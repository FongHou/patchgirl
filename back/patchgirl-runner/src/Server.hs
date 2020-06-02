{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE DataKinds       #-}
{-# LANGUAGE TypeOperators   #-}

module Server(run, mkApp) where

import qualified Data.CaseInsensitive              as CI
import           Data.Functor                      ((<&>))
import qualified GHC.Natural                       as Natural
import qualified Network.Connection                as Tls
import qualified Network.HTTP.Client.TLS           as Tls
import qualified Network.HTTP.Types.Header         as HTTP
import qualified Network.HTTP.Types.Method         as HTTP
import           Network.Wai                       (Middleware)
import qualified Network.Wai                       as Wai
import qualified Network.Wai.Handler.Warp          as Warp
import qualified Network.Wai.Middleware.Cors       as Wai
import qualified Network.Wai.Middleware.Prometheus as Prometheus
import qualified Prometheus
import qualified Prometheus.Metric.GHC             as Prometheus
import qualified Say
import           Servant                           hiding (BadPassword,
                                                    NoSuchUser)


import           Api
import           Env
import           Model
import           RequestComputation.App



-- * run


run :: IO ()
run = do
  putStrLn "Running web server for web"
  env :: Env <- createEnv Say.sayString ioRequestRunner
  _ <- Prometheus.register Prometheus.ghcMetrics
  app :: Application <- mkApp env <&> cors
  let promMiddleware :: Middleware = Prometheus.prometheus $ Prometheus.PrometheusSettings ["metrics"] True True
  Warp.run (Natural.naturalToInt $ _envPort env ) (promMiddleware app)


-- * cors


cors :: Middleware
cors =
  Wai.cors onlyRequestForCors
  where
    onlyRequestForCors :: Wai.Request -> Maybe Wai.CorsResourcePolicy
    onlyRequestForCors request =
      case Wai.pathInfo request of
        "api" : "runner" : _  ->
          Just Wai.CorsResourcePolicy { Wai.corsOrigins = Just (allowedOrigins, True)
                                      , Wai.corsMethods = [ HTTP.methodPost, HTTP.methodOptions ]
                                      , Wai.corsRequestHeaders = Wai.simpleResponseHeaders <> allowedRequestHeaders
                                      , Wai.corsExposedHeaders = Nothing
                                      , Wai.corsMaxAge = Nothing
                                      , Wai.corsVaryOrigin = False
                                      , Wai.corsRequireOrigin = True
                                      , Wai.corsIgnoreFailures = False
                                      }
        _ -> Nothing

    allowedOrigins :: [ Wai.Origin ]
    allowedOrigins =
      [ "https://dev.patchgirl.io"
      , "https://patchgirl.io"
      ]

    allowedRequestHeaders :: [ HTTP.HeaderName ]
    allowedRequestHeaders =
      [ "content-type"
      , "x-xsrf-token"
      ] <&> CI.mk



-- * mk app


mkApp :: Env -> IO Application
mkApp env = do
  let tlsSettings = Tls.TLSSettingsSimple True False False
  -- this manager will mainly be used by RequestComputation
  Tls.setGlobalManager =<< Tls.newTlsManagerWith (Tls.mkManagerSettings tlsSettings Nothing)
  let
    context = EmptyContext
    webApiProxy = Proxy :: Proxy RunnerApi
    apiServer = runnerApiServer
    server =
      hoistServerWithContext webApiProxy Proxy (appMToHandler env) apiServer
  return $
    serveWithContext webApiProxy context server
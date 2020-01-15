{-# LANGUAGE DuplicateRecordFields  #-}
{-# LANGUAGE FlexibleInstances      #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE OverloadedStrings      #-}
{-# LANGUAGE TemplateHaskell        #-}

module Foo where

import           Data.ByteString
import           Data.ByteString.UTF8 as BSU
import           Data.Text.Encoding   as TSE
import           Servant.Auth.Server  as Jose
{-
--main :: IO ByteString
main = do
  secret <- Jose.writeKey ".appKey.test"
  return ()
  --print $ BSU.toString secret
-}
  --Jose.writeKey "foo"
{-
import qualified Data.ByteString.Lazy.Char8 as L8
import           Network.HTTP.Client
import           Network.HTTP.Client.TLS
import           Network.HTTP.Simple

foo :: IO ()
foo = do
    request' <- parseRequest "http://httpbin.org/post"
    let request
            = setRequestMethod "PUT"
            $ setRequestPath "/put"
            $ setRequestQueryString [("hello", Just "world")]
            $ setRequestBodyLBS "This is my request body"
            $ setRequestSecure True
            $ setRequestPort 443
            $ request'
    response <- httpBS request

    putStrLn $ "The status code was: " ++
               show (getResponseStatusCode response)
    print $ getResponseHeader "Content-Type" response

--    manager <- newManager $ managerSetProxy noProxy tlsManagerSettings
--    setGlobalManager manager

    manager <- newTlsManager
    setGlobalManager manager

    let request = "https://swapi.co/api/people/1/"
    print request
    response <- httpBS request

    putStrLn $ "The status code was: " ++
               show (getResponseStatusCode response)
    print $ getResponseHeader "Content-Type" response
    --L8.putStrLn $ getResponseBody response
-}

{-# LANGUAGE DataKinds                 #-}
{-# LANGUAGE DuplicateRecordFields     #-}
{-# LANGUAGE FlexibleContexts          #-}
{-# LANGUAGE FlexibleInstances         #-}
{-# LANGUAGE NoMonomorphismRestriction #-}

module Scene.AppSpec where

import           Control.Lens.Getter ((^.))
import qualified Data.Maybe          as Maybe
import           Data.UUID           (UUID)
import qualified Data.UUID           as UUID
import qualified Network.HTTP.Types  as HTTP
import           Servant             hiding (Header)
import qualified Servant.Auth.Client as Auth
import qualified Servant.Auth.Server as Auth
import           Servant.Client      (ClientM, client)
import           Test.Hspec

import           DBUtil
import           Helper.App
import           PatchGirl.Web.Server
import           PatchGirl.Web.Api
import           PatchGirl.Web.RequestCollection.Model
import           PatchGirl.Web.RequestNode.Model
import           PatchGirl.Web.ScenarioCollection.Model
import           PatchGirl.Web.ScenarioNode.Model


-- * client


createSceneHandler :: Auth.Token -> UUID -> NewScene -> ClientM ()
deleteSceneHandler :: Auth.Token -> UUID -> UUID -> ClientM ()
updateSceneHandler :: Auth.Token -> UUID -> UUID -> UpdateScene -> ClientM ()
createSceneHandler
  :<|> deleteSceneHandler
  :<|> updateSceneHandler =
  client (Proxy :: Proxy (SceneActorApi '[Auth.JWT]))


-- * spec


spec :: Spec
spec =
  withClient (defaultEnv2 >>= mkApp) $ do


-- ** create scene


    describe "create a scene" $ do
      it "returns 404 when scenario collection doesnt exist" $ \clientEnv ->
        createAccountAndcleanDBAfter $ \Test { token } -> do
          let newScene = mkNewScene UUID.nil Nothing UUID.nil "" ""
          try clientEnv (createSceneHandler token UUID.nil newScene) `shouldThrow` errorsWithStatus HTTP.notFound404

      it "returns 404 when scenario node doesnt exist" $ \clientEnv ->
        createAccountAndcleanDBAfter $ \Test { connection, accountId, token } -> do
          _ <- insertSampleScenarioCollection accountId connection
          let newScene = mkNewScene UUID.nil Nothing UUID.nil "" ""
          try clientEnv (createSceneHandler token UUID.nil newScene) `shouldThrow` errorsWithStatus HTTP.notFound404

      it "returns 404 when scenario node exists but isn't a scenario file" $ \clientEnv ->
        createAccountAndcleanDBAfter $ \Test { connection, accountId, token } -> do
          (_, ScenarioCollection _ scenarioNodes) <- insertSampleScenarioCollection accountId connection
          let folderId = Maybe.fromJust (getFirstScenarioFolder scenarioNodes) ^. scenarioNodeId
          let newScene = mkNewScene UUID.nil Nothing UUID.nil "" ""
          try clientEnv (createSceneHandler token folderId newScene) `shouldThrow` errorsWithStatus HTTP.notFound404

      it "returns 404 if the related request file doesnt belong to the account" $ \clientEnv ->
        createAccountAndcleanDBAfter $ \Test { connection, accountId, token } -> do
          (accountId2, _) <- withAccountAndToken defaultNewFakeAccount2 connection
          (_, ScenarioCollection _ scenarioNodes) <- insertSampleScenarioCollection accountId connection
          RequestCollection _ requestNodes <- insertSampleRequestCollection accountId2 connection
          let requestFileId = Maybe.fromJust (getFirstFile requestNodes) ^. requestNodeId
          let scenarioFile = Maybe.fromJust (getFirstScenarioFile scenarioNodes)
          let scenarioFileId = scenarioFile ^. scenarioNodeId
          let newScene = mkNewScene UUID.nil Nothing requestFileId "" ""
          try clientEnv (createSceneHandler token scenarioFileId newScene) `shouldThrow` errorsWithStatus HTTP.notFound404

      it "creates a root scene" $ \clientEnv ->
        createAccountAndcleanDBAfter $ \Test { connection, accountId, token } -> do
          (RequestCollection _ requestNodes, ScenarioCollection _ scenarioNodes) <- insertSampleScenarioCollection accountId connection
          let requestFileId = Maybe.fromJust (getFirstFile requestNodes) ^. requestNodeId
          let scenarioFile = Maybe.fromJust (getFirstScenarioFile scenarioNodes)
          let scenarioFileId = scenarioFile ^. scenarioNodeId
          let scenarioFirstScene = head $ scenarioFile ^. scenarioNodeScenes
          let newScene = mkNewScene UUID.nil Nothing requestFileId "" ""
          try clientEnv (createSceneHandler token scenarioFileId newScene)
          newCreatedScene <- selectFakeScene UUID.nil connection
          newCreatedScene `shouldBe` Just (FakeScene { _fakeSceneParentId = Nothing
                                                     , _fakeSceneId = requestFileId
                                                     , _fakeActorType = HttpActor
                                                     , _fakeScenePrescript = ""
                                                     , _fakeScenePostscript = ""
                                                     })
          newSon <- selectFakeSceneWithParentId UUID.nil connection
          newSon `shouldBe` Just (FakeScene { _fakeSceneParentId = Just UUID.nil
                                            , _fakeSceneId = scenarioFirstScene ^. sceneActorId
                                            , _fakeActorType = HttpActor
                                            , _fakeScenePrescript = ""
                                            , _fakeScenePostscript = ""
                                            })

      it "creates an http scene" $ \clientEnv ->
        createAccountAndcleanDBAfter $ \Test { connection, accountId, token } -> do
          (RequestCollection _ requestNodes, ScenarioCollection _ scenarioNodes) <- insertSampleScenarioCollection accountId connection
          let requestFileId = Maybe.fromJust (getFirstFile requestNodes) ^. requestNodeId
          let scenarioFile = Maybe.fromJust (getFirstScenarioFile scenarioNodes)
          let scenarioFileId = scenarioFile ^. scenarioNodeId
          let scenarioFirstScene = head $ scenarioFile ^. scenarioNodeScenes
          let newScene = mkNewScene UUID.nil (Just $ scenarioFirstScene ^. sceneId) requestFileId "" ""
          try clientEnv (createSceneHandler token scenarioFileId newScene)
          newCreatedScene <- selectFakeScene UUID.nil connection
          newCreatedScene `shouldBe` Just (FakeScene { _fakeSceneParentId = Just $ scenarioFirstScene ^. sceneId
                                                     , _fakeSceneId = requestFileId
                                                     , _fakeActorType = HttpActor
                                                     , _fakeScenePrescript = ""
                                                     , _fakeScenePostscript = ""
                                                     })

      it "creates a pg scene" $ \clientEnv ->
        createAccountAndcleanDBAfter $ \Test { connection, accountId, token } -> do
          (RequestCollection _ requestNodes, ScenarioCollection _ scenarioNodes) <- insertSampleScenarioCollection accountId connection
          let requestFileId = Maybe.fromJust (getFirstFile requestNodes) ^. requestNodeId
          let scenarioFile = Maybe.fromJust (getFirstScenarioFile scenarioNodes)
          let scenarioFileId = scenarioFile ^. scenarioNodeId
          let scenarioFirstScene = head $ scenarioFile ^. scenarioNodeScenes
          let newScene = mkNewScene UUID.nil (Just $ scenarioFirstScene ^. sceneId) requestFileId "" ""
          try clientEnv (createSceneHandler token scenarioFileId newScene)
          newCreatedScene <- selectFakeScene UUID.nil connection
          newCreatedScene `shouldBe` Just (FakeScene { _fakeSceneParentId = Just $ scenarioFirstScene ^. sceneId
                                                     , _fakeSceneId = requestFileId
                                                     , _fakeActorType = HttpActor
                                                     , _fakeScenePrescript = ""
                                                     , _fakeScenePostscript = ""
                                                     })


-- ** delete scene


    describe "delete a scene" $ do
      it "returns 404 when scenario collection doesnt exist" $ \clientEnv ->
        createAccountAndcleanDBAfter $ \Test { token } ->
          try clientEnv (deleteSceneHandler token UUID.nil UUID.nil) `shouldThrow` errorsWithStatus HTTP.notFound404

      it "returns 404 when scenario node doesnt exist" $ \clientEnv ->
        createAccountAndcleanDBAfter $ \Test { connection, accountId, token } -> do
          _ <- insertSampleScenarioCollection accountId connection
          try clientEnv (deleteSceneHandler token UUID.nil UUID.nil) `shouldThrow` errorsWithStatus HTTP.notFound404

      it "returns 404 when scenario node exists but is a scenario folder" $ \clientEnv ->
        createAccountAndcleanDBAfter $ \Test { connection, accountId, token } -> do
          (_, ScenarioCollection _ scenarioNodes) <- insertSampleScenarioCollection accountId connection
          let folderId = Maybe.fromJust (getFirstScenarioFolder scenarioNodes) ^. scenarioNodeId
          try clientEnv (deleteSceneHandler token folderId UUID.nil) `shouldThrow` errorsWithStatus HTTP.notFound404

      it "delete a scene" $ \clientEnv ->
        createAccountAndcleanDBAfter $ \Test { connection, accountId, token } -> do
          (RequestCollection _ _, ScenarioCollection _ scenarioNodes) <- insertSampleScenarioCollection accountId connection
          let scenarioFile = Maybe.fromJust (getFirstScenarioFile scenarioNodes)
          let scenarioFileId = scenarioFile ^. scenarioNodeId
          let sceneId' = head (scenarioFile ^. scenarioNodeScenes) ^. sceneId
          try clientEnv (deleteSceneHandler token scenarioFileId sceneId')
          selectFakeScene sceneId' connection >>= (`shouldSatisfy` Maybe.isNothing)


-- ** update scene


    describe "update a scene" $ do
      it "returns 404 when scenario collection doesnt exist" $ \clientEnv ->
        createAccountAndcleanDBAfter $ \Test { token } -> do
          let updateScene = mkUpdateScene "" ""
          try clientEnv (updateSceneHandler token UUID.nil UUID.nil updateScene) `shouldThrow` errorsWithStatus HTTP.notFound404

      it "returns 404 when scenario node exists but is a scenario folder" $ \clientEnv ->
        createAccountAndcleanDBAfter $ \Test { connection, accountId, token } -> do
          (_, ScenarioCollection _ scenarioNodes) <- insertSampleScenarioCollection accountId connection
          let updateScene = mkUpdateScene "" ""
          let folderId = Maybe.fromJust (getFirstScenarioFolder scenarioNodes) ^. scenarioNodeId
          try clientEnv (updateSceneHandler token folderId UUID.nil updateScene) `shouldThrow` errorsWithStatus HTTP.notFound404

      it "update a scene" $ \clientEnv ->
        createAccountAndcleanDBAfter $ \Test { connection, accountId, token } -> do
          (RequestCollection _ _, ScenarioCollection _ scenarioNodes) <- insertSampleScenarioCollection accountId connection
          let scenarioFile = Maybe.fromJust (getFirstScenarioFile scenarioNodes)
          let scenarioFileId = scenarioFile ^. scenarioNodeId
          let sceneId' = head (scenarioFile ^. scenarioNodeScenes) ^. sceneId
          let updateScene = mkUpdateScene "prescript!" "postscript!"
          try clientEnv (updateSceneHandler token scenarioFileId sceneId' updateScene)
          FakeScene{..} <- Maybe.fromJust <$> selectFakeScene sceneId' connection
          _fakeScenePrescript `shouldBe` "prescript!"



  where
    mkNewScene :: UUID -> Maybe UUID -> UUID -> String -> String -> NewScene
    mkNewScene id parentId requestFileId prescript postscript =
      NewScene { _newSceneId = id
               , _newSceneSceneActorParentId = parentId
               , _newSceneActorType = HttpActor
               , _newSceneActorId = requestFileId
               , _newScenePrescript = prescript
               , _newScenePostscript = postscript
               }

    mkUpdateScene :: String -> String -> UpdateScene
    mkUpdateScene prescript postscript =
      UpdateScene { _updateScenePrescript = prescript
                  , _updateScenePostscript = postscript
                  }

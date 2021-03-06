{-# LANGUAGE DeriveAnyClass    #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE FlexibleContexts  #-}


module PatchGirl.Web.ScenarioCollection.Model where


import           Data.Aeson
import           Data.UUID                          (UUID)
import qualified Database.PostgreSQL.Simple.FromRow as PG
import           GHC.Generics

import           PatchGirl.Web.ScenarioNode.Model

-- * Model


data ScenarioCollection =
  ScenarioCollection UUID [ScenarioNode]
  deriving (Eq, Show, Generic, ToJSON, FromJSON, PG.FromRow)

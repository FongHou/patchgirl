{-# LANGUAGE DeriveAnyClass   #-}
{-# LANGUAGE DeriveGeneric    #-}
{-# LANGUAGE FlexibleContexts #-}


module PatchGirl.Web.PgCollection.Model where

import           Data.Aeson
import           Data.UUID                          (UUID)
import qualified Database.PostgreSQL.Simple.FromRow as PG
import           GHC.Generics

import           PatchGirl.Web.PgNode.Model


-- * Model


data PgCollection =
  PgCollection UUID [PgNode]
  deriving (Eq, Show, Generic, ToJSON, FromJSON, PG.FromRow)

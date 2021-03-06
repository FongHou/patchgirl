{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric  #-}

module PatchGirl.Web.Environment.Model ( KeyValue(..)
                         , keyValueId
                         , keyValueKey
                         , keyValueValue
                         , keyValueHidden
                         , PGEnvironmentWithKeyValue(..)
                         , pgEnvironmentWithKeyValueEnvironmentId
                         , pgEnvironmentWithKeyValueEnvironmentName
                         , pgEnvironmentWithKeyValueKeyValueId
                         , pgEnvironmentWithKeyValueKey
                         , pgEnvironmentWithKeyValueValue
                         , pgEnvironmentWithKeyValueHidden
                         , PGEnvironmentWithoutKeyValue(..)
                         , pgEnvironmentWithoutKeyValueEnvironmentId
                         , pgEnvironmentWithoutKeyValueEnvironmentName
                         , NewKeyValue(..)
                         , newKeyValueId
                         , newKeyValueKey
                         , newKeyValueValue
                         , newKeyValueHidden
                         , Environment(..)
                         , environmentId
                         , environmentName
                         , environmentKeyValues
                         , UpdateEnvironment(..)
                         , updateEnvironmentName
                         , NewEnvironment(..)
                         , newEnvironmentId
                         , newEnvironmentName
                         ) where

import           Control.Lens               (makeLenses)
import           Data.Aeson                 (FromJSON, ToJSON (..),
                                             defaultOptions, fieldLabelModifier,
                                             genericToJSON, parseJSON)
import           Data.Aeson.Types           (genericParseJSON)
import qualified Database.PostgreSQL.Simple as PG
import           GHC.Generics
import Data.UUID (UUID)


-- * key value


data KeyValue =
  KeyValue { _keyValueId    :: UUID
           , _keyValueKey   :: String
           , _keyValueValue :: String
           , _keyValueHidden :: Bool
           } deriving (Eq, Show, Generic, PG.FromRow)

instance FromJSON KeyValue where
  parseJSON =
    genericParseJSON defaultOptions { fieldLabelModifier = drop 1 }

instance ToJSON KeyValue where
  toJSON =
    genericToJSON defaultOptions { fieldLabelModifier = drop 1 }

$(makeLenses ''KeyValue)


-- * environment


data Environment
  = Environment { _environmentId        :: UUID
                , _environmentName      :: String
                , _environmentKeyValues :: [KeyValue]
                } deriving (Eq, Show, Generic)

instance FromJSON Environment where
  parseJSON =
    genericParseJSON defaultOptions { fieldLabelModifier = drop 1 }

instance ToJSON Environment where
  toJSON =
    genericToJSON defaultOptions { fieldLabelModifier = drop 1 }

$(makeLenses ''Environment)


-- * get environments


data PGEnvironmentWithKeyValue =
  PGEnvironmentWithKeyValue { _pgEnvironmentWithKeyValueEnvironmentId   :: UUID
                            , _pgEnvironmentWithKeyValueEnvironmentName :: String
                            , _pgEnvironmentWithKeyValueKeyValueId      :: UUID
                            , _pgEnvironmentWithKeyValueKey             :: String
                            , _pgEnvironmentWithKeyValueValue           :: String
                            , _pgEnvironmentWithKeyValueHidden          :: Bool
                            } deriving (Generic, PG.FromRow)

data PGEnvironmentWithoutKeyValue =
  PGEnvironmentWithoutKeyValue { _pgEnvironmentWithoutKeyValueEnvironmentId   :: UUID
                               , _pgEnvironmentWithoutKeyValueEnvironmentName :: String
                               } deriving (Generic, PG.FromRow)


$(makeLenses ''PGEnvironmentWithKeyValue)
$(makeLenses ''PGEnvironmentWithoutKeyValue)


-- * new environment


data NewEnvironment
  = NewEnvironment { _newEnvironmentId :: UUID
                   , _newEnvironmentName :: String
                   } deriving (Eq, Show, Generic)

instance FromJSON NewEnvironment where
  parseJSON =
    genericParseJSON defaultOptions { fieldLabelModifier = drop 1 }

instance ToJSON NewEnvironment where
  toJSON =
    genericToJSON defaultOptions { fieldLabelModifier = drop 1 }

$(makeLenses ''NewEnvironment)


-- * update environment


newtype UpdateEnvironment
  = UpdateEnvironment { _updateEnvironmentName :: String }
  deriving (Eq, Show, Generic)

instance ToJSON UpdateEnvironment where
  toJSON =
    genericToJSON defaultOptions { fieldLabelModifier = drop 1 }

$(makeLenses ''UpdateEnvironment)

instance FromJSON UpdateEnvironment where
  parseJSON =
    genericParseJSON defaultOptions { fieldLabelModifier = drop 1 }


-- * upsert key values


data NewKeyValue
  = NewKeyValue { _newKeyValueId   :: UUID
                , _newKeyValueKey   :: String
                , _newKeyValueValue :: String
                , _newKeyValueHidden  :: Bool
                }
  deriving (Eq, Show, Generic)

instance FromJSON NewKeyValue where
  parseJSON =
    genericParseJSON defaultOptions { fieldLabelModifier = drop 1 }

instance ToJSON NewKeyValue where
  toJSON =
    genericToJSON defaultOptions { fieldLabelModifier = drop 1 }

$(makeLenses ''NewKeyValue)

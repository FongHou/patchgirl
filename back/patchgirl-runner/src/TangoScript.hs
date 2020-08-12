{-# LANGUAGE DeriveGeneric #-}

module TangoScript ( TangoAst
                   , Proc(..)
                   , Expr(..)
                   , exprToString
                   ) where

import qualified Data.Aeson          as Aeson
import           Data.HashMap.Strict (HashMap)
import qualified Data.HashMap.Strict as HashMap (HashMap)
import           GHC.Generics        (Generic)


type TangoAst = [Proc]


-- * proc


data Proc
  = AssertEqual Expr Expr
  | Let String Expr
  | Set String Expr
  deriving (Show, Eq, Generic)

instance Aeson.ToJSON Proc where
  toJSON =
    Aeson.genericToJSON Aeson.defaultOptions { Aeson.fieldLabelModifier = drop 1 }

instance Aeson.FromJSON Proc where
  parseJSON =
    Aeson.genericParseJSON Aeson.defaultOptions { Aeson.fieldLabelModifier = drop 1 }


-- * expr


data Expr
  = EJson Json
  | EList [Expr]
  | LBool Bool
  | LInt Int
  | LFloat Float
  | LNull
  | LString String
  | Var String
  | Fetch String
  | Eq Expr Expr
  | Add Expr Expr
  | HttpResponseBodyAsString
  | HttpResponseStatus
  | PgResponseAsTable
  deriving (Show, Eq, Generic)

instance Aeson.ToJSON Expr where
  toJSON =
    Aeson.genericToJSON Aeson.defaultOptions { Aeson.fieldLabelModifier = drop 1 }

instance Aeson.FromJSON Expr where
  parseJSON =
    Aeson.genericParseJSON Aeson.defaultOptions { Aeson.fieldLabelModifier = drop 1 }


-- ** json


data Json
    = JInt Int
    | JFloat Float
    | JBool Bool
    | JString String
    | JArray [Json]
    | JObject (HashMap String Json)
    deriving (Show, Eq, Generic)

instance Aeson.ToJSON Json where
  toJSON =
    Aeson.genericToJSON Aeson.defaultOptions { Aeson.fieldLabelModifier = drop 1 }

instance Aeson.FromJSON Json where
  parseJSON =
    Aeson.genericParseJSON Aeson.defaultOptions { Aeson.fieldLabelModifier = drop 1 }


-- * util


exprToString :: Expr -> Maybe String
exprToString = \case
  LBool bool -> Just $ show bool
  LInt int -> Just $ show int
  LString string -> Just string
  Var _ -> Nothing
  Fetch _ -> Nothing
  Eq _ _ -> Nothing
  Add _ _ -> Nothing
  HttpResponseBodyAsString -> Nothing
  HttpResponseStatus -> Nothing

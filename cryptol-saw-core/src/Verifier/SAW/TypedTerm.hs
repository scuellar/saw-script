{- |
Module      : SAWScript.TypedTerm
Description : SAW-Core terms paired with Cryptol types.
License     : BSD3
Maintainer  : huffman
Stability   : provisional
-}
module Verifier.SAW.TypedTerm where

import Data.Map (Map)
import qualified Data.Map as Map

import Cryptol.ModuleSystem.Name (nameIdent)
import qualified Cryptol.TypeCheck.AST as C
import Cryptol.Utils.PP (pretty)

import Verifier.SAW.Cryptol (scCryptolType)
import Verifier.SAW.Recognizer (asExtCns)
import Verifier.SAW.SharedTerm

-- Typed terms -----------------------------------------------------------------

-- | Within SAWScript, we represent an object language term as a
-- SAWCore shared term paired with a Cryptol type schema. The Cryptol
-- type is used for type inference/checking of inline Cryptol
-- expressions.

data TypedTerm =
  TypedTerm
  { ttSchema :: C.Schema
  , ttTerm :: Term
  }
  deriving Show

ttTermLens :: Functor f => (Term -> f Term) -> TypedTerm -> f TypedTerm
ttTermLens f tt = tt `seq` fmap (\x -> tt{ttTerm = x}) (f (ttTerm tt))

-- | Deprecated.
mkTypedTerm :: SharedContext -> Term -> IO TypedTerm
mkTypedTerm sc trm = do
  ty <- scTypeOf sc trm
  ct <- scCryptolType sc ty
  return $ TypedTerm (C.Forall [] [] ct) trm

-- Typed external constants ----------------------------------------------------

data TypedExtCns =
  TypedExtCns
  { tecType :: C.Type
  , tecExt :: ExtCns Term
  }
  deriving Show

-- | Recognize 'TypedTerm's that are external constants.
asTypedExtCns :: TypedTerm -> Maybe TypedExtCns
asTypedExtCns (TypedTerm schema t) =
  do cty <- C.isMono schema
     ec <- asExtCns t
     pure $ TypedExtCns cty ec

abstractTypedExts :: SharedContext -> [TypedExtCns] -> TypedTerm -> IO TypedTerm
abstractTypedExts sc tecs (TypedTerm (C.Forall params props ty) trm) =
  do let tys = map tecType tecs
     let exts = map tecExt tecs
     let ty' = foldr C.tFun ty tys
     trm' <- scAbstractExts sc exts trm
     pure $ TypedTerm (C.Forall params props ty') trm'

-- Typed modules ---------------------------------------------------------------

-- | In SAWScript, we can refer to a Cryptol module as a first class
-- value. These are represented simply as maps from names to typed
-- terms.

data CryptolModule =
  CryptolModule (Map C.Name C.TySyn) (Map C.Name TypedTerm)

showCryptolModule :: CryptolModule -> String
showCryptolModule (CryptolModule sm tm) =
  unlines $
    (if Map.null sm then [] else
       "Type Synonyms" : "=============" : map showTSyn (Map.elems sm) ++ [""]) ++
    "Symbols" : "=======" : map showBinding (Map.assocs tm)
  where
    showTSyn (C.TySyn name params _props rhs _doc) =
      "    " ++ unwords (pretty (nameIdent name) : map pretty params) ++ " = " ++ pretty rhs
    showBinding (name, TypedTerm schema _) =
      "    " ++ pretty (nameIdent name) ++ " : " ++ pretty schema

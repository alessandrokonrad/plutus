{-# OPTIONS_GHC -fno-warn-orphans      #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE FlexibleInstances         #-}
{-# LANGUAGE LambdaCase                #-}
{-# LANGUAGE MultiParamTypeClasses     #-}
{-# LANGUAGE OverloadedStrings         #-}
{-# LANGUAGE RecordWildCards           #-}
{-# LANGUAGE ScopedTypeVariables       #-}
{-# LANGUAGE StandaloneDeriving        #-}
{-# LANGUAGE TemplateHaskell           #-}

module PlutusCore.Generators.NEAT.Type where

{-
!!! THIS FILE IS GENERATED FROM Type.agda
!!! DO NOT EDIT THIS FILE. EDIT Type.agda
!!! AND THEN RUN agda2hs ON IT.
-}












import Control.Enumerable
import Control.Monad.Except
import PlutusCore
import PlutusCore.Generators.NEAT.Common

newtype Neutral a = Neutral
  { unNeutral :: a
  }

data TypeBuiltinG = TyByteStringG
                  | TyIntegerG
                  | TyBoolG
                  | TyUnitG
                  | TyStringG
                  | TyListG TypeBuiltinG
                  | TyDataG
                      deriving stock (Show, Eq, Ord)

deriveEnumerable ''TypeBuiltinG

data TypeG n = TyVarG n
             | TyFunG (TypeG n) (TypeG n)
             | TyIFixG (TypeG n) (Kind ()) (TypeG n)
             | TyForallG (Kind ()) (TypeG (S n))
             | TyBuiltinG TypeBuiltinG
             | TyLamG (TypeG (S n))
             | TyAppG (TypeG n) (TypeG n) (Kind ())
                 deriving stock (Eq, Ord, Show)

deriving stock instance Ord (Kind ())

deriveEnumerable ''Kind

deriveEnumerable ''TypeG

type ClosedTypeG = TypeG Z

instance Functor TypeG where
  fmap = ren

ext :: (m -> n) -> S m -> S n
ext _ FZ     = FZ
ext f (FS x) = FS (f x)

ren :: (m -> n) -> TypeG m -> TypeG n
ren f (TyVarG x)          = TyVarG (f x)
ren f (TyFunG ty1 ty2)    = TyFunG (ren f ty1) (ren f ty2)
ren f (TyIFixG ty1 k ty2) = TyIFixG (ren f ty1) k (ren f ty2)
ren f (TyForallG k ty)    = TyForallG k (ren (ext f) ty)
ren _ (TyBuiltinG b)      = TyBuiltinG b
ren f (TyLamG ty)         = TyLamG (ren (ext f) ty)
ren f (TyAppG ty1 ty2 k)  = TyAppG (ren f ty1) (ren f ty2) k

exts :: (n -> TypeG m) -> S n -> TypeG (S m)
exts _ FZ     = TyVarG FZ
exts s (FS i) = ren FS (s i)

sub :: (n -> TypeG m) -> TypeG n -> TypeG m
sub s (TyVarG i)             = s i
sub s (TyFunG ty1 ty2)       = TyFunG (sub s ty1) (sub s ty2)
sub s (TyIFixG ty1 k ty2)    = TyIFixG (sub s ty1) k (sub s ty2)
sub s (TyForallG k ty)       = TyForallG k (sub (exts s) ty)
sub _ (TyBuiltinG tyBuiltin) = TyBuiltinG tyBuiltin
sub s (TyLamG ty)            = TyLamG (sub (exts s) ty)
sub s (TyAppG ty1 ty2 k)     = TyAppG (sub s ty1) (sub s ty2) k

instance Monad TypeG where
  a >>= f = sub f a
--  return = pure

instance Applicative TypeG where
  (<*>) = ap
  pure = TyVarG


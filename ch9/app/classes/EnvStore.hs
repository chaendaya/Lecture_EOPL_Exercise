{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# HLINT ignore "Use camelCase" #-}
{-# HLINT ignore "Eta reduce" #-}
module EnvStore where

import Ref(Location)
import Expr (Identifier,Exp,ClassDecl(..),MethodDecl(..))

import Data.Maybe
import Data.List (elemIndex,lookup)

-- Environment
data Env =
    Empty_env
  | Extend_env [Identifier] [Location] Env
  | Extend_env_rec [(Identifier,[Identifier],Exp)] Env
  | Extend_env_with_self_and_super Object Identifier Env

apply_env :: Env -> Store -> Identifier -> (DenVal, Store)
apply_env Empty_env store search_var = error (search_var ++ " is not found.")
apply_env (Extend_env saved_vars saved_vals saved_env) store search_var = 
  if search_var `elem` saved_vars
    then (Loc_Val $ saved_vals !! (fromJust $ Data.List.elemIndex search_var saved_vars),store)
    else apply_env saved_env store search_var
apply_env (Extend_env_rec idIdExpList saved_env) store search_var
  | isIn      = let (l,store') = newref store procVal in (Loc_Val l,store')
  | otherwise = apply_env saved_env store search_var
  where isIn      = or [ p_name==search_var | (p_name,b_var,p_body) <- idIdExpList ]
        procVal = head [ Proc_Val (procedure b_var p_body (Extend_env_rec idIdExpList saved_env)) 
                       | (p_name,b_var,p_body) <- idIdExpList, p_name==search_var ]
apply_env (Extend_env_with_self_and_super obj super_name saved_env) store search_var
  | search_var == "%self"  = error "TODO: implement an apply_env function"
  | search_var == "%super" = error "TODO: implement an apply_env function"
  | otherwise = error "TODO: implement an apply_env function"

-- Abstract data type interfaces for Env
empty_env :: Env
empty_env = Empty_env

extend_env :: [Identifier] -> [Location] -> Env -> Env
extend_env xs vs env = Extend_env xs vs env

extend_env_rec :: [(Identifier,[Identifier],Exp)] -> Env -> Env
extend_env_rec idIdListExpList env = Extend_env_rec idIdListExpList env

extend_env_with_self_and_super :: Object -> Identifier -> Env -> Env
extend_env_with_self_and_super obj super_name env = 
  error "TODO: implement an extend_env_with_self_and_super function"

-- Expressed values
data ExpVal =
    Num_Val {expval_num :: Int}
  | Bool_Val {expval_bool :: Bool}
  | Proc_Val {expval_proc :: Proc}
  -- | Ref_Val {expval_loc :: Location}
  | List_Val {expval_list :: [ExpVal]} -- Listof_Val?
  | Object_Val  {expval_obj :: Object}
  | Uninitialized_Val  -- for uninitialized fields (Not in the textbook)

instance Show ExpVal where
  show (Num_Val num)   = show num
  show (Bool_Val bool) = show bool
  show (Proc_Val proc) = show proc  -- "<proc>"
  show (List_Val list) = "(" ++ showWithSp list ++ ")" -- Todo: print a list as [1,2,3] instead of (1,2,3)??
  show (Object_Val obj) = show obj
  show (Uninitialized_Val) = "<uninitialized>"

showWithSp :: [ExpVal] -> String
showWithSp [] = ""
showWithSp [x] = show x
showWithSp (x:xs) = show x ++ " " ++ showWithSp xs  

-- Denoted values
data DenVal = 
    Loc_Val {denval_loc :: Location} -- Ref(ExpVal) 
  | SelfObject_Val {denval_self :: Object} -- for %self
  | SuperClassName_Val {denval_super :: Identifier} -- for %super

-- Procedure values : data structures
data Proc = Procedure {proc_vars :: [Identifier], proc_body :: Exp, saved_env :: Env}

instance Show Proc where
  show (Procedure vars body saved_env) = show "<proc>"

procedure :: [Identifier] -> Exp -> Env -> Proc
procedure vars body env = Procedure vars body env

-- Object values : data structures
data Object = AnObject {object_class_name :: Identifier, object_fields :: [Location]}

instance Show Object where
  show (AnObject class_name fields) = 
    "<" ++ show class_name ++ ":object>"

-- In Interp.hs
-- apply_procedure :: Proc -> ExpVal -> ExpVal
  
-- | Store.hs
type Store = (Location, [(Location,ExpVal)]) -- Next new location

newref :: Store -> ExpVal -> (Location,Store)
newref (next,s) v = (next,(next+1,(next,v):s))

deref :: Store -> Location -> ExpVal
deref (next,s) loc =
  case [v | (loc',v) <- s, loc==loc'] of
    (v:_) -> v
    _     -> error ("Location not found: " ++ show loc)

setref :: Store -> Location -> ExpVal -> Store
setref (next,s) loc v = (next,update s)
  where update [] = error ("Invalid reference: " ++ show loc)
        update ((loc',w):s')
          | loc==loc' = (loc,v):s'
          | otherwise = (loc',w):update s'

initStore :: Store
initStore = (1,[])

-- Classes
data Class = AClass 
  { class_super_name :: Maybe Identifier, 
    class_field_names :: [Identifier], 
    class_method_env :: MethodEnv
  }

new_object :: Identifier -> ClassEnv -> Store -> (Object, Store)
new_object class_name class_env store = 
  error "TODO: implement a new_object function"

-- Methods
data Method = AMethod 
  { method_vars :: [Identifier], 
    method_body :: Exp,
    method_super_name :: Identifier,
    method_field_names :: [Identifier]
  }

-- apply_method in Interp.hs

-- Class Environments
type ClassEnv = [ (Identifier,Class) ]

add_to_class_env :: Identifier -> Class -> ClassEnv -> ClassEnv
add_to_class_env class_name aClass class_env = 
  (class_name,aClass) : class_env

lookup_class :: Identifier -> ClassEnv -> Class
lookup_class class_name class_env = 
  case Data.List.lookup class_name class_env of
    Just aClass -> aClass
    Nothing    -> error ("Class " ++ class_name ++ " not found.")

--
initialize_class_env :: [ClassDecl] -> ClassEnv
initialize_class_env classDecls = 
  foldl (flip initialize_class_decl) initClassEnv classDecls    

initClassEnv :: ClassEnv
initClassEnv = error "TODO: implement an initClassEnv"

initialize_class_decl :: ClassDecl -> ClassEnv -> ClassEnv
initialize_class_decl (Class_Decl class_name super_name field_names method_decls) class_env = 
  error "TODO: implement an initialize_class_decl"

-- Fields
append_field_names :: [Identifier] -> [Identifier] -> [Identifier]
append_field_names super_fields new_fields =
  error "TODO: implement an append_field_names"

-- Method Environments
type MethodEnv = [ (Identifier, Method)]

find_method :: Identifier -> Identifier -> ClassEnv -> Method
find_method class_name method_name class_env = 
    error "TODO: implement an find_method"

method_decls_method_envs :: [MethodDecl] -> Identifier -> [Identifier] -> MethodEnv
method_decls_method_envs method_decls super_name field_names = 
  error "TODO: implement an method_decls_method_envs"

merge_method_envs :: MethodEnv -> MethodEnv -> MethodEnv
merge_method_envs superMethodEnvs newMethodEnvs = 
  error "TODO: implement an merge_method_envs"


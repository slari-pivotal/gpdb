--
-- The catalog pg_cast stores data type conversion paths, both built-in 
-- paths and those defined with CREATE CAST.
--
--	Name		Type  References		Description
--  ----------  ----  -----------  -----------------------  
--	castsource	oid	  pg_type.oid  OID of the source data type
--  casttarget	oid	  pg_type.oid  OID of the target data type
--  castfunc	oid	  pg_proc.oid  OID of the function to use to perform this 
--					  			     cast. Zero is stored if the data types are 
-- 								     binary compatible 
--  castcontext	char	 		   Indicates what contexts the cast may be 
--								     invoked in:
--									 'e' means only as an explicit cast. 
--									 'a' means implicitly in assignment to a 
--									     target column, as well as explicitly.
-- 									 'i' means implicitly in expressions, as 
--                                       well as the other cases
--
-- The cast functions listed in pg_cast must always take the cast
-- source type as their first argument type, and return the cast
-- destination type as their result type. A cast function can have up
-- to three arguments. The second argument, if present, must be type
-- integer; it receives the type modifier associated with the
-- destination type, or -1 if there is none. The third argument, if
-- present, must be type boolean; it receives true if the cast is an
-- explicit cast, false otherwise.
--
-- It is legitimate to create a pg_cast entry in which the source and
-- target types are the same, if the associated function takes more
-- than one argument. Such entries represent "length coercion
-- functions" that coerce values of the type to be legal for a
-- particular type modifier value. Note however that at present there
-- is no support for associating non-default type modifiers with
-- user-created data types, and so this facility is only of use for
-- the small number of built-in types that have type modifier syntax
-- built into the grammar.
--
-- When a pg_cast entry has different source and target types and a
-- function that takes more than one argument, it represents
-- converting from one type to another and applying a length coercion
-- in a single step. When no such entry is available, coercion to a
-- type that uses a type modifier involves two steps, one to convert
-- between data types and a second to apply the modifier.
--
\d pg_cast

select 
  n1.nspname as sourcenamespace,
  t1.typname as sourcetype,
  n2.nspname as targetnamespace,
  t2.typname as targettype,
  c.castfunc::regproc,
  c.castcontext
from
  pg_cast c
  left join pg_type t1 on (c.castsource = t1.oid)
  left join pg_type t2 on (c.casttarget = t2.oid)
  left join pg_namespace n1 on (t1.typnamespace = n1.oid)
  left join pg_namespace n2 on (t2.typnamespace = n2.oid)
order by n1.nspname, t1.typname, n2.nspname, t2.typname;
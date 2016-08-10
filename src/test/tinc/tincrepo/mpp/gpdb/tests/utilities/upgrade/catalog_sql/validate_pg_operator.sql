--
-- pg_operator
--
--  The catalog pg_operator stores information about operators. 
--
--   Name          Type     References        Description
--   oprname       name                       Name of the operator
--   oprnamespace  oid      pg_namespace.oid  The OID of the namespace that contains this operator
--   oprowner      oid      pg_authid.oid     Owner of the operator
--   oprkind       char                       b = infix ("both"), l = prefix ("left"), r = postfix ("right")
--   oprcanhash    bool                       This operator supports hash joins
--   oprleft       oid      pg_type.oid       Type of the left operand
--   oprright      oid      pg_type.oid       Type of the right operand
--   oprresult     oid      pg_type.oid       Type of the result
--   oprcom        oid      pg_operator.oid   Commutator of this operator, if any
--   oprnegate     oid      pg_operator.oid   Negator of this operator, if any
--   oprlsortop    oid      pg_operator.oid   merge join: operator that sorts the type of the left-hand operand (L<L)
--   oprrsortop    oid      pg_operator.oid   merge joins: the operator that sorts the type of the right-hand operand (R<R)
--   oprltcmpop    oid      pg_operator.oid   merge joins: the less-than operator that compares the left and right operand types (L<R)
--   oprgtcmpop    oid      pg_operator.oid   merge joins: the greater-than operator that compares the left and right operand types (L>R)
--   oprcode       regproc  pg_proc.oid       Function that implements this operator
--   oprrest       regproc  pg_proc.oid       Restriction selectivity estimation function for this operator
--   oprjoin       regproc  pg_proc.oid       Join selectivity estimation function for this operator
-- 

\d pg_operator

select
  n.nspname as namespace,
  o.oprname,
  t1.typname as oprleft,
  t2.typname as oprright,
  o.oprkind,
  o.oprcanhash,
  o.oprresult::regtype,
  o.oprcom::regoper,
  o.oprnegate::regoperator,
  o.oprlsortop::regoperator,
  o.oprrsortop::regoperator,
  o.oprltcmpop::regoperator,
  o.oprcode,
  o.oprrest,
  o.oprjoin
from pg_operator o
left join pg_namespace n on (o.oprnamespace = n.oid)
left join pg_authid r on (o.oprowner = r.oid)
left join pg_type t1 on (o.oprleft = t1.oid)
left join pg_type t2 on (o.oprright = t2.oid)
order by n.nspname, o.oprname, t1.typname, t2.typname;

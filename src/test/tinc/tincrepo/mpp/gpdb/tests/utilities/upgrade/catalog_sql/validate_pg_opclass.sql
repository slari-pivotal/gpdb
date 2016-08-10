--
-- pg_opclass
--
-- The catalog pg_opclass defines index access method operator
-- classes. Each operator class defines semantics for index columns of
-- a particular data type and a particular index access method. Note
-- that there can be multiple operator classes for a given data
-- type/access method combination, thus supporting multiple behaviors.
--
--   Name         Type  References        Description
--   -----------  ----  ----------------  ------------------------------
--   opcamid      oid   pg_am.oid         Index access method operator class is for
--   opcname      name                    Name of this operator class
--   opcnamespace oid   pg_namespace.oid  Namespace of this operator class
--   opcowner     oid   pg_authid.oid     Owner of the operator class
--   opcintype    oid   pg_type.oid       Data type that the operator class indexes
--   opcdefault   bool                    True if this operator class is the default for opcintype
--   opckeytype   oid   pg_type.oid       Type of data stored in index, or zero if same as opcintype
--
-- The majority of the information defining an operator class is
-- actually not in its pg_opclass row, but in the associated rows in
-- pg_amop and pg_amproc. Those rows are considered to be part of the
-- operator class definition — this is not unlike the way that a
-- relation is defined by a single pg_class row plus associated rows
-- in pg_attribute and other tables.
--

\d pg_opclass

select 
  n.nspname as namespace,
  op.opcname,
  m.amname as access_method,
  op.opcintype::regtype,
  op.opcdefault,
  op.opckeytype::regtype
from pg_opclass op
left join pg_namespace n on (op.opcnamespace = n.oid)
left join pg_authid o on (op.opcowner = o.oid)
left join pg_am m on (op.opcamid = m.oid)
order by n.nspname, op.opcname, m.amname;

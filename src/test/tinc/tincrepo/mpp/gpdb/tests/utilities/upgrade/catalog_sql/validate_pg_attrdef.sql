--
-- The catalog pg_attrdef stores column default values. 
--   The main information about columns is stored in pg_attribute. 
--   Only columns that explicitly specify a default value will have an entry here.
--
--   Name	 Type	References			  Description
--   ------- -----  -------------------   --------------------------------
--   adrelid  oid	pg_class.oid 	      The table this column belongs to
--   adnum	  int2	pg_attribute.attnum	  The number of the column
--   adbin 	  text	 					  The internal representation of the column default value
--   adsrc	  text	 					  A human-readable representation of the default value
--
-- The adsrc field is historical, and is best not used, because it does not track outside 
-- changes that might affect the representation of the default value. 
-- Reverse-compiling the adbin field (with pg_get_expr for example) is a better way to display the default value. 
--
\d pg_attrdef

select 
  n.nspname,
  r.relname,
  a.adnum,
  pg_get_expr(a.adbin, a.adrelid) as default
from pg_catalog.pg_attrdef a
left join pg_class r on (r.oid = a.adrelid)
left join pg_namespace n on (n.oid = r.relnamespace)
order by n.nspname, r.relname, a.adnum;


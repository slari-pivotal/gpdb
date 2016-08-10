--
-- check pg_attribute_encoding (Added in Rio)
--

\d pg_attribute_encoding

CREATE OR REPLACE FUNCTION array_to_rows(myarray ANYARRAY) RETURNS SETOF 
ANYELEMENT AS $$
  BEGIN
    FOR j IN 1..ARRAY_UPPER(myarray,1) LOOP
      RETURN NEXT myarray[j];
    END LOOP;
    RETURN;
  END;
$$ LANGUAGE 'plpgsql';

select
  n.nspname,
  c.relname,
  a.attnum,
  array_to_rows(a.attoptions)
from
  pg_attribute_encoding a,
  pg_class c,
  pg_namespace n
where a.attrelid = c.oid
  and c.relnamespace = n.oid
order by 1,2,3,4;

select
  n.nspname,
  c.relname,
  a.attnum,
  array_to_rows(a.attoptions)
from
  pg_attribute_encoding a,
  pg_class c,
  pg_namespace n
where a.attrelid = c.oid
  and c.relnamespace = n.oid
order by 1,2,3,4;

drop function array_to_rows(myarray ANYARRAY);

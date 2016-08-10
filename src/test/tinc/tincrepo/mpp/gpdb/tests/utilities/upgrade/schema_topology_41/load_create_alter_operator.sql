create database db_test_bed;
\c db_test_bed
CREATE FUNCTION new_complex_add(numeric, numeric) RETURNS numeric 
    AS '/data/gpdb_p1/anu/cdbfast/main/schema_topology/funcs','add_one'
    LANGUAGE c STRICT; 

CREATE OPERATOR %+ ( 
    leftarg = numeric, 
    rightarg = numeric, 
    procedure = new_complex_add, 
    commutator = + 
);

CREATE FUNCTION complex_sub(numeric) RETURNS numeric 
    AS '/data/gpdb_p1/anu/cdbfast/main/schema_topology/funcs','add_one'
    LANGUAGE c STRICT; 

CREATE OPERATOR @-( leftarg = numeric,
   procedure = complex_sub
);

CREATE OPERATOR @* ( 
    leftarg = numeric, 
    rightarg = numeric, 
    procedure = new_complex_add, 
    negator = <>,
    HASHES,
    SORT1= <,
    SORT2= >,
    LTCMP = <,
    GTCMP = >
);

CREATE OPERATOR @+( 
    leftarg = numeric, 
    rightarg = numeric, 
    procedure = new_complex_add, 
    negator = <>,
    RESTRICT = eqsel,
    JOIN= eqjoinsel,
    MERGES,
    SORT1= <,
    SORT2= >,
    LTCMP = <,
    GTCMP = >
);


CREATE ROLE op_owner;
ALTER OPERATOR @+(numeric,numeric) OWNER TO op_owner;
ALTER OPERATOR @-(numeric,NONE) OWNER TO op_owner;

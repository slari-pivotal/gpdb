SELECT * FROM ao_4_3;

UPDATE ao_4_3 SET j = j+100 WHERE i = 5;

DELETE FROM ao_4_3 WHERE i = 1;

SELECT * FROM ao_4_3;

SET gp_select_invisible=true;

SELECT * FROM ao_4_3;

SET gp_select_invisible=false;

SELECT * FROM gp_dist_random('pg_aoseg.pg_aoseg_<RELFILENODE>');

VACUUM ao_4_3;

SELECT * FROM gp_dist_random('pg_aoseg.pg_aoseg_<RELFILENODE>');

SELECT * FROM ao_4_3;

SET gp_select_invisible=true;

SELECT * FROM ao_4_3;

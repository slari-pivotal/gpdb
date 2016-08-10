SELECT * FROM aoco_4_3;

UPDATE aoco_4_3 SET j = j+100 WHERE i = 5;

DELETE FROM aoco_4_3 WHERE i = 1;

SELECT * FROM aoco_4_3;

SET gp_select_invisible=true;

SELECT * FROM aoco_4_3;

SET gp_select_invisible=false;

SELECT segno,tupcount,varblockcount,modcount,state FROM gp_dist_random('pg_aoseg.pg_aocsseg_<RELFILENODE>');

VACUUM aoco_4_3;

SELECT segno,tupcount,varblockcount,modcount,state FROM gp_dist_random('pg_aoseg.pg_aocsseg_<RELFILENODE>');

SELECT * FROM aoco_4_3;

SET gp_select_invisible=true;

SELECT * FROM aoco_4_3;

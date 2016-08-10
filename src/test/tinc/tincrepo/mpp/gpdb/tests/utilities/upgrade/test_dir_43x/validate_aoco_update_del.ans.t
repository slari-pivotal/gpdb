SELECT * FROM aoco_4_3;
 i |  j  
---+-----
 1 | 101
 2 | 102
 3 | 103
 4 | 104
 5 | 105
(5 rows)

UPDATE aoco_4_3 SET j = j+100 WHERE i = 5;
UPDATE 1
DELETE FROM aoco_4_3 WHERE i = 1;
DELETE 1
SELECT * FROM aoco_4_3;
 i |  j  
---+-----
 2 | 102
 3 | 103
 4 | 104
 5 | 205
(4 rows)

SET gp_select_invisible=true;
SET
SELECT * FROM aoco_4_3;
 i |  j  
---+-----
 1 | 101
 2 | 102
 3 | 103
 4 | 104
 5 | 105
 5 | 205
(6 rows)

SET gp_select_invisible=false;
SET
SELECT segno,tupcount,varblockcount,modcount,state FROM gp_dist_random('pg_aoseg.pg_aocsseg_<RELFILENODE>');
 segno | tupcount | varblockcount | modcount | state 
-------+----------+---------------+----------+-------
     1 |        6 |             0 |        2 |     1
(1 row)

VACUUM aoco_4_3;
VACUUM
SELECT segno,tupcount,varblockcount,modcount,state FROM gp_dist_random('pg_aoseg.pg_aocsseg_<RELFILENODE>');
 segno | tupcount | varblockcount | modcount | state 
-------+----------+---------------+----------+-------
     2 |        4 |             0 |        1 |     1
     1 |        0 |             0 |        2 |     1
(2 rows)

SELECT * FROM aoco_4_3;
 i |  j  
---+-----
 2 | 102
 3 | 103
 4 | 104
 5 | 205
(4 rows)

SET gp_select_invisible=true;
SET
SELECT * FROM aoco_4_3;
 i |  j  
---+-----
 2 | 102
 3 | 103
 4 | 104
 5 | 205
(4 rows)


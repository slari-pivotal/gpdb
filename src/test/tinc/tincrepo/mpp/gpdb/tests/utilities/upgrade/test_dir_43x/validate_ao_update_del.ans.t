SELECT * FROM ao_4_3;
 i |  j  
---+-----
 1 | 101
 2 | 102
 3 | 103
 4 | 104
 5 | 105
(5 rows)

UPDATE ao_4_3 SET j = j+100 WHERE i = 5;
UPDATE 1
DELETE FROM ao_4_3 WHERE i = 1;
DELETE 1
SELECT * FROM ao_4_3;
 i |  j  
---+-----
 2 | 102
 3 | 103
 4 | 104
 5 | 205
(4 rows)

SET gp_select_invisible=true;
SET
SELECT * FROM ao_4_3;
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
SELECT * FROM gp_dist_random('pg_aoseg.pg_aoseg_<RELFILENODE>');
 segno | eof | tupcount | varblockcount | eofuncompressed | modcount | state 
-------+-----+----------+---------------+-----------------+----------+-------
     1 | 168 |        6 |             2 |             168 |        2 |     1
(1 row)

VACUUM ao_4_3;
VACUUM
SELECT * FROM gp_dist_random('pg_aoseg.pg_aoseg_<RELFILENODE>');
 segno | eof | tupcount | varblockcount | eofuncompressed | modcount | state 
-------+-----+----------+---------------+-----------------+----------+-------
     2 | 104 |        4 |             1 |             104 |        1 |     1
     1 |   0 |        0 |             0 |               0 |        2 |     1
(2 rows)

SELECT * FROM ao_4_3;
 i |  j  
---+-----
 2 | 102
 3 | 103
 4 | 104
 5 | 205
(4 rows)

SET gp_select_invisible=true;
SET
SELECT * FROM ao_4_3;
 i |  j  
---+-----
 2 | 102
 3 | 103
 4 | 104
 5 | 205
(4 rows)


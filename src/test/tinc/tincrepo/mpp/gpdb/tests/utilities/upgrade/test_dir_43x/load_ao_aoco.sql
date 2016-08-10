DROP TABLE IF EXISTS ao_4_3;

CREATE TABLE ao_4_3 (i int,j int) WITH (appendonly = true) DISTRIBUTED RANDOMLY;

\d+ ao_4_3;

INSERT INTO ao_4_3 SELECT i , i+100 FROM generate_series(1,5) AS i;

DROP TABLE IF EXISTS aoco_4_3;

CREATE TABLE aoco_4_3 (i int,j int) WITH (appendonly = true, orientation=column) DISTRIBUTED RANDOMLY;

\d+ aoco_4_3;

INSERT INTO aoco_4_3 SELECT i , i+100 FROM generate_series(1,5) AS i;

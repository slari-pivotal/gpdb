DROP TABLE IF EXISTS foo;
CREATE TABLE foo (c int, d int);
INSERT INTO foo select i, i+1 from generate_series(1,10) i;

DROP TABLE IF EXISTS bar;
CREATE TABLE bar (c int, d int);
INSERT INTO bar select i, i+1 from generate_series(1,10) i;

DROP TABLE IF EXISTS aotab;
CREATE TABLE aotab (c int, d int) WITH(appendonly = true);
INSERT INTO aotab select i, i+1 from generate_series(1,10)i;

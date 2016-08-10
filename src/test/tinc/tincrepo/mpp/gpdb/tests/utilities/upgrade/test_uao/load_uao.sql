DROP TABLE IF EXISTS ao;
DROP TABLE IF EXISTS aocs;
DROP TABLE IF EXISTS ao_drop;
DROP TABLE IF EXISTS aocs_drop;

CREATE TABLE ao (a INT, b INT) WITH (appendonly=true);
CREATE TABLE ao_drop (a INT, b INT) WITH (appendonly=true);
CREATE TABLE aocs (a INT, b INT) WITH (appendonly=true, orientation=column);
CREATE TABLE aocs_drop (a INT, b INT) WITH (appendonly=true, orientation=column);

INSERT INTO ao SELECT i as a, i as b FROM generate_series(1, 10) AS i;
INSERT INTO ao_drop SELECT i as a, i as b FROM generate_series(1, 10) AS i;
INSERT INTO aocs SELECT i as a, i as b FROM generate_series(1, 10) AS i;
INSERT INTO aocs_drop SELECT i as a, i as b FROM generate_series(1, 10) AS i;


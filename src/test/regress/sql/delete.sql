CREATE TABLE delete_test (
    id SERIAL PRIMARY KEY,
    a INT
) DISTRIBUTED BY (id);

INSERT INTO delete_test (a) VALUES (10);
INSERT INTO delete_test (a) VALUES (50);
INSERT INTO delete_test (a) VALUES (100);

-- allow an alias to be specified for DELETE's target table
DELETE FROM delete_test AS dt WHERE dt.a > 75;

-- if an alias is specified, don't allow the original table name
-- to be referenced
BEGIN;
SET LOCAL add_missing_from = false;
DELETE FROM delete_test dt WHERE delete_test.a > 25;
ROLLBACK;

SELECT * FROM delete_test;

DROP TABLE delete_test;

--
-- MPP-28949: Fixup target lists of plans in appendplans of Append node
--
SET gp_autostats_mode = none;
CREATE TABLE foo_fixup (mrkt_id integer NOT NULL, acct_key bigint NOT NULL,
seq_nr numeric(10,0) NOT NULL)
DISTRIBUTED BY (mrkt_id ,acct_key) PARTITION BY LIST(mrkt_id)
(PARTITION it VALUES(50) WITH (tablename='foo_prt_it', appendonly=false ),
PARTITION pt VALUES(64) WITH (tablename='foo_prt_pt', appendonly=false ));
INSERT INTO foo_fixup VALUES(50,6419293312,10);
INSERT INTO foo_fixup VALUES(50,6419293312,11);
INSERT INTO foo_fixup VALUES(50,6419293313,12);
INSERT INTO foo_fixup VALUES(64,6419293313,12);
CREATE TABLE bar_fixup (mrkt_id int, acct_key bigint, tran_dt_key int, misc_tran_typ_id int, lcl_bus_id int, seq_nr numeric(10,0));
INSERT INTO bar_fixup VALUES(50,6419293312,20170609,19961,423,10);
INSERT INTO bar_fixup VALUES(50,1483120867,20170609,19961,423,11);
INSERT INTO bar_fixup VALUES(50,1483120867,20170609,19961,423,12);
INSERT INTO bar_fixup VALUES(64,1483120867,20170609,19961,423,12);
EXPLAIN DELETE FROM foo_fixup f WHERE f.mrkt_id = 50 AND (f.mrkt_id,  f.seq_nr) IN (SELECT t.mrkt_id, t.seq_nr FROM bar_fixup t WHERE t.mrkt_id = 50);
DELETE FROM foo_fixup f WHERE f.mrkt_id = 50 AND (f.mrkt_id,  f.seq_nr) IN (SELECT t.mrkt_id, t.seq_nr FROM bar_fixup t WHERE t.mrkt_id = 50);
SELECT * FROM foo_fixup;

DROP TABLE foo_fixup;
DROP TABLE bar_fixup;
RESET gp_autostats_mode;

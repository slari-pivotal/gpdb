INSERT INTO ao SELECT i as a, i as b FROM generate_series(11, 20) AS i;
INSERT INTO aocs SELECT i as a, i as b FROM generate_series(11, 20) AS i;
SELECT a FROM ao ORDER BY a;
SELECT a FROM aocs ORDER BY a;
DELETE FROM ao WHERE a = 1;
DELETE FROM aocs WHERE a = 1;
UPDATE ao SET b = 0 WHERE a = 2;
UPDATE aocs SET b = 0 WHERE a = 2;

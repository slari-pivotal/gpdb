-- Install a helper function to inject faults, using the fault injection
-- mechanism built into the server.
CREATE FUNCTION gp_inject_fault(
  faultname text,
  type text,
  ddl text,
  database text,
  tablename text,
  numoccurrences int4,
  sleeptime int4,
  db_id smallint)
RETURNS boolean
AS '$libdir/gp_inject_fault'
LANGUAGE C VOLATILE STRICT NO SQL;

-- inject fault of type sleep on all primaries
select gp_inject_fault('checkpoint',
       'sleep', '', '', '', 1, 2, dbid) from gp_segment_configuration
       where role = 'p' and content > -1;
-- check fault status
select gp_inject_fault('checkpoint',
       'status', '', '', '', 1, 2, dbid) from gp_segment_configuration
       where role = 'p' and content > -1;
-- Calling checkpoint should trigger the fault
checkpoint;
-- fault status should indicate it's triggered
select gp_inject_fault('checkpoint',
       'status', '', '', '', 1, 2, dbid) from gp_segment_configuration
       where role = 'p' and content > -1;
-- reset the fault on all primaries
select gp_inject_fault('checkpoint',
       'reset', '', '', '', 1, 2, dbid) from gp_segment_configuration
       where role = 'p' and content > -1;

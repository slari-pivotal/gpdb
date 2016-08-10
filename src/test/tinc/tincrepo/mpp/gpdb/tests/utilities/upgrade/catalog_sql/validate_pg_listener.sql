--
-- pg_listener
--
-- The catalog pg_listener supports the LISTEN and NOTIFY commands. A
-- listener creates an entry in pg_listener for each notification name
-- it is listening for. A notifier scans pg_listener and updates each
-- matching entry to show that a notification has occurred. The
-- notifier also sends a signal (using the PID recorded in the table)
-- to awaken the listener from sleep.
--
--  Name          Type  References   Description
--  relname	      name               Notify condition name. (1)
--  listenerpid   int4	             PID of the server process that created this entry
--  notification  int4	             Zero if no event is pending for this listener. (2)
--                                   
--
-- (1) The name need not match any actual relation in the database; 
--     the name relname is historical.
-- (2) If an event is pending, the PID of the server process that sent 
--     the notification
--

\d pg_listener

-- There is no useful validation that we can run on pg_listener?
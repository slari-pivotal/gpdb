SELECT relname , b.relid, visimaprelid, visimapidxid
FROM pg_class a , pg_appendonly b
WHERE a.oid = b.relid AND a.relname = 'ao_4_3';
 relname | relid | visimaprelid | visimapidxid 
---------+-------+--------------+--------------
 ao_4_3  | <RELFILENODE> |        <VISIMAPID> |        <VISIMAPIDX>
(1 row)


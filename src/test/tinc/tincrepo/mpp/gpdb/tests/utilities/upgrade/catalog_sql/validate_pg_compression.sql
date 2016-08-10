--
-- pg_compression (Added in Rio)
--

\d pg_compression

select 
  compname,
  compconstructor::regproc,
  compdestructor::regproc,
  compcompressor::regproc,
  compdecompressor::regproc,
  compvalidator::regproc
from pg_compression c 
left join pg_authid i on (c.compowner = i.oid)
order by c.compowner, c.compconstructor, c.compcompressor;

select
  compname,
  compconstructor::regproc,
  compdestructor::regproc,
  compcompressor::regproc,
  compdecompressor::regproc,
  compvalidator::regproc
from pg_compression c
left join pg_authid i on (c.compowner = i.oid)
order by c.compowner, c.compconstructor, c.compcompressor;

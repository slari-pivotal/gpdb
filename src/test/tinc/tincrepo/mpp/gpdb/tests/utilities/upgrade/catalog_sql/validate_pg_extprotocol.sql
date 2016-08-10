--
-- pg_extprotocol (Added in Rio)
--

\d pg_extprotocol

select 
    a.ptcname, 
    a.ptcreadfn::regproc, 
    a.ptcwritefn::regproc, 
    a.ptcvalidatorfn::regproc, 
    a.ptctrusted
from 
    pg_extprotocol a
left join pg_authid i on (a.ptcowner = i.oid)
order by 
    a.ptcname, a.ptcreadfn;

select
    a.ptcname,
    a.ptcreadfn::regproc,
    a.ptcwritefn::regproc,
    a.ptcvalidatorfn::regproc,
    a.ptctrusted
from
    pg_extprotocol a
left join pg_authid i on (a.ptcowner = i.oid)
order by
    a.ptcname, a.ptcreadfn;

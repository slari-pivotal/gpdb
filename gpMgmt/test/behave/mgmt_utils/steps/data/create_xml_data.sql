create TABLE testxml as select (xpath('//foo/text()'::text, '<foo>bar</foo>'::xml))[1] as cx1 distributed randomly ;
insert into testxml values ('<?xml version="1.0"?><note><to>Tove</to><body>hello</body></note>' ) ;
insert into testxml values ('<?xml version="1.0"?><!DOCTYPE note SYSTEM "note.dtd"><note><to>Tove</to><body>hello</body></note>' ) ;
insert into testxml values ('<foo>bar</foo>'::xml);
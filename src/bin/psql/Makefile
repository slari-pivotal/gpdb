#-------------------------------------------------------------------------
#
# Makefile for src/bin/psql
#
# Portions Copyright (c) 1996-2012, PostgreSQL Global Development Group
# Portions Copyright (c) 1994, Regents of the University of California
#
# src/bin/psql/Makefile
#
#-------------------------------------------------------------------------

PGFILEDESC = "psql - the PostgreSQL interactive terminal"
PGAPPICON=win32

subdir = src/bin/psql
top_builddir = ../../..
include $(top_builddir)/src/Makefile.global

REFDOCDIR= $(top_srcdir)/doc/src/sgml/ref

override CPPFLAGS := -DFRONTEND -I. -I$(srcdir) -I$(libpq_srcdir) -I$(top_srcdir)/src/bin/pg_dump $(CPPFLAGS)

# necessary to get flex to play nice with large files on 32bit solaris sparc
ifeq ($(PORTNAME), solaris)
#ifeq ($(host_cpu), sparc)
ifneq ($(enable_largefile), no)
override CFLAGS := -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE=1
endif
#endif
endif

OBJS=	command.o common.o help.o input.o stringutils.o mainloop.o copy.o \
	startup.o prompt.o variables.o large_obj.o print.o describe.o \
	tab-complete.o mbprint.o dumputils.o keywords.o kwlookup.o \
	sql_help.o \
	$(WIN32RES)

FLEXFLAGS = -Cfe -b -p -p

# The frontend doesn't need everything that's in LIBS, some are backend only
LIBS := $(filter-out -lresolv -lbz2, $(LIBS))

all: psql

psql: $(OBJS) | submake-libpq submake-libpgport
	$(CC) $(CFLAGS) $(OBJS) $(libpq_pgport) $(LDFLAGS) $(LDFLAGS_EX) $(LIBS) -o $@$(X)

help.o: sql_help.h

dumputils.c keywords.c: % : $(top_srcdir)/src/bin/pg_dump/%
	rm -f $@ && $(LN_S) $< .

kwlookup.c: % : $(top_srcdir)/src/backend/parser/%
	rm -f $@ && $(LN_S) $< .

sql_help.c: sql_help.h ;
sql_help.h: create_help.pl $(wildcard $(REFDOCDIR)/*.sgml)
	$(PERL) $< $(REFDOCDIR) $*

# psqlscan is compiled as part of mainloop
mainloop.o: psqlscan.c

psqlscan.c: psqlscan.l
ifdef FLEX
	$(FLEX) $(FLEXFLAGS) -o'$(srcdir)/psqlscan.c' $<
else
	@$(missing) flex $< $@
endif

distprep: sql_help.h psqlscan.c

install: all installdirs
	$(INSTALL_PROGRAM) psql$(X) '$(DESTDIR)$(bindir)/psql$(X)'
	$(INSTALL_DATA) $(srcdir)/psqlrc.sample '$(DESTDIR)$(datadir)/psqlrc.sample'

installdirs:
	$(MKDIR_P) '$(DESTDIR)$(bindir)'

uninstall:
	rm -f '$(DESTDIR)$(bindir)/psql$(X)' '$(DESTDIR)$(datadir)/psqlrc.sample'

# psqlscan.c is in the distribution tarball, so is not cleaned here
clean distclean:
	rm -f psql$(X) $(OBJS) dumputils.c keywords.c kwlookup.c psqlscan.o

maintainer-clean: distclean
	rm -f sql_help.h sql_help.c psqlscan.c

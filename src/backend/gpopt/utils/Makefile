#-------------------------------------------------------------------------
#
# Makefile--
#    Makefile for gpopt
#
#-------------------------------------------------------------------------

subdir = src/backend/gpopt/utils
top_builddir = ../../../..
include $(top_builddir)/src/Makefile.global

OBJS = COptTasks.o CCatalogUtils.o CConstExprEvaluatorProxy.o nodeutils.o funcs.o

funcs.o: funcs.cpp
	$(COMPILE.cpp) -fPIC $(OUTPUT_OPTION) $<

include $(top_srcdir)/src/backend/common.mk

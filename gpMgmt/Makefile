top_builddir = ../..
include $(top_builddir)/src/Makefile.global

INSTLOC=$(prefix)

#---------------------------------------------------------------------
# Set Version
#---------------------------------------------------------------------

SET_VERSION_SCRIPTS = \
	bin/gpactivatestandby \
	bin/gpaddmirrors \
	bin/gpbitmapreindex \
	bin/gpcheckos \
	bin/gpcheckperf \
	bin/gpcrondump.py \
	bin/gpdbrestore \
	bin/gpdeletesystem \
	bin/gpexpand \
	bin/gpfilespace \
	bin/gpinitstandby \
	bin/gpinitsystem \
	bin/gpload.py \
	bin/gplogfilter \
	bin/gpmigrator \
	bin/gpmigrator_mirror \
	bin/gpmovemirrors \
	bin/gprebuildsystem \
	bin/gprecoverseg \
	bin/gpreload \
	bin/gpscp \
	bin/gpsizecalc \
	bin/gpskew \
	bin/gpssh \
	bin/gpssh-exkeys \
	bin/gpstart \
	bin/gpstate \
	bin/gpstop \
	bin/gpsys1 \
	bin/lib/gpcheckcat \
	sbin/gpaddconfig.py \
	sbin/gpchangeuserpassword \
	sbin/gpcheck_hostdump \
	sbin/gpcleansegmentdir.py \
	sbin/gpfixuserlimts \
	sbin/gpgetstatususingtransition.py \
	sbin/gprepairmirrorseg.py \
	sbin/gpsegstart.py \
	sbin/gpsegstop.py \
	sbin/gpsegtoprimaryormirror.py \
	sbin/gpsetdbid.py \
	sbin/gpsuspend.py \
	sbin/gpupgrademirror.py \
	lib/python/gppylib/programs/clsAddMirrors.py \
	lib/python/gppylib/programs/clsHostCacheLookup.py \
	lib/python/gppylib/programs/clsInjectFault.py \
	lib/python/gppylib/programs/clsRecoverSegment.py \
	lib/python/gppylib/programs/clsSystemState.py \
	lib/python/gppylib/programs/gppkg.py \
	lib/python/gppylib/programs/kill.py \
	lib/python/gppylib/programs/verify.py \
	lib/python/gppylib/mainUtils.py \
	$(NULL)

set_scripts_version :
	@for file in $(SET_VERSION_SCRIPTS); do \
	    if [ -f $(INSTLOC)/$${file} ]; then \
	        perl $(top_builddir)/putversion $(INSTLOC)/$${file} ; \
	    fi ; \
	done

install:
#	#Copy the management utilities
	mkdir -p $(INSTLOC)/bin
	mkdir -p $(INSTLOC)/lib
	mkdir -p $(INSTLOC)/lib/python
	mkdir -p $(INSTLOC)/sbin

	#Setup /lib/python contents
	cp -rp bin/gppylib $(INSTLOC)/lib/python
	cp -rp bin/ext/* $(INSTLOC)/lib/python
	cp -rp bin $(INSTLOC)

#ifeq "$(findstring $(BLD_ARCH),$(GPPKG_PLATFORMS))" ""
#	@echo "Removing gppkg from distribution"
#	rm -f $(INSTLOC)/bin/gppkg
#endif

	cp -rp sbin/* $(INSTLOC)/sbin/.
	#cp -p extensions/gpfdist/gpfdist$(EXE_EXT) $(INSTLOC)/bin/
	cp $(top_builddir)/src/test/regress/*.pl $(INSTLOC)/bin
	if [ ! -d ${INSTLOC}/docs ] ; then mkdir ${INSTLOC}/docs ; fi
	if [ -d doc ]; then cp -rp doc $(INSTLOC)/docs/cli_help; fi
	if [ -d demo/gpmapreduce ]; then \
	  mkdir -p $(INSTLOC)/demo; \
	  $(TAR) -C demo -czf $(INSTLOC)/demo/gpmapreduce.tar.gz gpmapreduce; \
	fi

#	THIS NEEDS TO MOVE
#	if [ -d demo/gpfdist_transform ]; then \
#	  mkdir -p $(INSTLOC)/demo; \
#	  $(TAR) -C demo -czf $(INSTLOC)/demo/gpfdist_transform.tar.gz gpfdist_transform; \
#	fi

	$(MAKE) set_scripts_version INSTLOC=$(INSTLOC)
	# Remove unwanted files.
	rm -rf $(INSTLOC)/bin/CVS
	rm -rf $(INSTLOC)/doc/CVS
	rm -rf $(INSTLOC)/bin/ext
	rm -rf $(INSTLOC)/bin/pythonSrc
	rm -rf $(INSTLOC)/bin/Makefile
	rm -rf $(INSTLOC)/bin/lib/CVS
	rm -rf $(INSTLOC)/bin/lib/.p4ignore
	rm -rf $(INSTLOC)/bin/src
	rm -f $(INSTLOC)/bin/gpchecksubnetcfg
	echo "`date` -- INFO: Removing $(INSTLOC)/bin/gpexpandsystem"
	rm -f $(INSTLOC)/bin/gpexpandsystem
	rm -rf $(INSTLOC)/bin/gppylib
	find $(INSTLOC)/lib/python/gppylib -name test -type d | xargs rm -rf

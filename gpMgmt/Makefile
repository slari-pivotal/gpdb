top_builddir = ..
include $(top_builddir)/src/Makefile.global
include $(top_builddir)/gpMgmt/Makefile.behave

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
	bin/gpcheckcat \
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
	    if [ -f $(prefix)/$${file} ]; then \
	        perl $(top_builddir)/putversion $(prefix)/$${file} ; \
	    fi ; \
	done

generate_greenplum_path_file:
	mkdir -p $(prefix)
	unset LIBPATH; \
	bin/generate-greenplum-path.sh $(prefix) > $(prefix)/greenplum_path.sh

install: generate_greenplum_path_file
	# Generate some python libraries
	$(MAKE) -C bin all prefix=$(prefix)

	#Copy the management utilities
	mkdir -p $(prefix)/bin
	mkdir -p $(prefix)/lib
	mkdir -p $(prefix)/lib/python
	mkdir -p $(prefix)/sbin

	#symlink gpcheckcat from bin to bin/lib to maintain backward compatibility
	if [ -f bin/gpcheckcat  ]; then \
		ln -sf ../gpcheckcat bin/lib/gpcheckcat; \
	fi

	#Setup /lib/python contents
	cp -Rp bin/gppylib $(prefix)/lib/python
	cp -Rp bin/ext/* $(prefix)/lib/python
	cp -Rp bin $(prefix)

	cp -Rp sbin/* $(prefix)/sbin/.
	cp $(top_builddir)/src/test/regress/*.pl $(prefix)/bin
	if [ ! -d ${prefix}/docs ] ; then mkdir ${prefix}/docs ; fi
	if [ -d doc ]; then cp -Rp doc $(prefix)/docs/cli_help; fi
	if [ -d demo/gpmapreduce ]; then \
	  mkdir -p $(prefix)/demo; \
	  $(TAR) -C demo -czf $(prefix)/demo/gpmapreduce.tar.gz gpmapreduce; \
	fi

	$(MAKE) set_scripts_version prefix=$(prefix)
	# Remove unwanted files.
	rm -rf $(prefix)/bin/CVS
	rm -rf $(prefix)/doc/CVS
	rm -rf $(prefix)/bin/ext
	rm -rf $(prefix)/bin/pythonSrc
	rm -rf $(prefix)/bin/Makefile
	rm -rf $(prefix)/bin/lib/CVS
	rm -rf $(prefix)/bin/lib/.p4ignore
	rm -rf $(prefix)/bin/src
	rm -f $(prefix)/bin/gpchecksubnetcfg
	echo "`date` -- INFO: Removing $(prefix)/bin/gpexpandsystem"
	rm -f $(prefix)/bin/gpexpandsystem
	rm -rf $(prefix)/bin/gppylib
	find $(prefix)/lib/python/gppylib -name test -type d | xargs rm -rf


# install svmtool and uplug
# use all targets for both sub-directories


all test install clean: uplug/Makefile svmtool/Makefile
	${MAKE} -C svmtool $@
	${MAKE} -C uplug $@


%/Makefile: %/Makefile.PL
	(cd $(dir $@) && perl Makefile.pl)

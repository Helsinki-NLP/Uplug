
# install MElt and uplug
# use all targets for both sub-directories


all test install clean: uplug/Makefile melt-0.6/Makefile
	${MAKE} -C melt-0.6 $@
	${MAKE} -C uplug $@


melt-0.6/Makefile:
	(cd melt-0.6 && ./configure)

uplug/Makefile: uplug/Makefile.PL
	(cd $(dir $@) && perl Makefile.pl)

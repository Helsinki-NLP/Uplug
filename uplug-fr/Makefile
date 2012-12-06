
# install MElt and uplug
# use all targets for both sub-directories

VERSION = 0.1

CONTENTS = $(shell ls) 

all test install clean: uplug/Makefile melt-0.6/Makefile
	${MAKE} -C melt-0.6 $@
	${MAKE} -C uplug $@

manifest: clean

dist: clean
	rm -f */Makefile.old
	mkdir -p $(notdir $(shell pwd))-$(VERSION)
	mv $(CONTENTS) $(notdir $(shell pwd))-$(VERSION)
	tar -czf $(notdir $(shell pwd))-$(VERSION).tar.gz $(notdir $(shell pwd))-$(VERSION)
	mv $(notdir $(shell pwd))-$(VERSION)/* .
	rmdir $(notdir $(shell pwd))-$(VERSION)

melt-0.6/Makefile:
	(cd melt-0.6 && ./configure)

uplug/Makefile: uplug/Makefile.PL
	(cd $(dir $@) && perl Makefile.pl)

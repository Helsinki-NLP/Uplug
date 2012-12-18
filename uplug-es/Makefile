
# install svmtool and uplug
# use all targets for both sub-directories

VERSION = 0.2

CONTENTS = $(shell ls) 

all test install clean: uplug/Makefile svmtool/Makefile
	${MAKE} -C svmtool $@
	${MAKE} -C uplug $@

manifest: clean

dist: clean
	rm -f */Makefile.old
	mkdir -p $(notdir $(shell pwd))-$(VERSION)
	mv $(CONTENTS) $(notdir $(shell pwd))-$(VERSION)
	tar -czf $(notdir $(shell pwd))-$(VERSION).tar.gz $(notdir $(shell pwd))-$(VERSION)
	mv $(notdir $(shell pwd))-$(VERSION)/* .
	rmdir $(notdir $(shell pwd))-$(VERSION)

dist-uplug: uplug/Makefile
	${MAKE} -C uplug manifest dist

%/Makefile: %/Makefile.PL
	(cd $(dir $@) && perl Makefile.PL)


VERSION = 0.3.1

PACKAGES = $(patsubst %,%-$(VERSION).tar.gz,\
	$(shell find . -maxdepth 1 -type d -name 'uplug*'))

all: dist

dist: $(PACKAGES)

$(PACKAGES): %-$(VERSION).tar.gz: %
	$(MAKE) $</Makefile
	$(MAKE) -C $< manifest dist
	mv $</*.tar.gz $@
	$(MAKE) -C $< clean

%/Makefile:
	cd $(dir $@) && perl Makefile.PL


MODULES = uplug-main $(wildcard uplug-??) uplug-treealign

all test install clean:
	for m in $(MODULES); do\
		$(MAKE) $$m/Makefile; \
		$(MAKE) -C $$m $@; \
	done


PACKAGES = $(patsubst %,%.tar.gz,$(shell find . -maxdepth 1 -type d -name 'uplug*'))

dist: $(PACKAGES)

$(PACKAGES): %.tar.gz: %
	$(MAKE) MODE=skip-compile $</Makefile
	$(MAKE) -C $< manifest dist
	mv $</*.tar.gz `ls $</*.tar.gz | sed 's/Uplug/$</'`
	mv $</*.tar.gz .
	$(MAKE) -C $< clean

%/Makefile:
	cd $(dir $@) && perl Makefile.PL $(MODE)


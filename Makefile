
MODULES = uplug-main $(wildcard uplug-??) uplug-treetagger

all test install:
	which uplug || echo "run 'make install-main' first"
	for m in $(MODULES); do\
		$(MAKE) $$m/Makefile; \
		$(MAKE) -C $$m $@; \
	done

clean:
	for m in $(MODULES); do\
		$(MAKE) $$m/Makefile; \
		$(MAKE) -C $$m $@; \
	done

install-main:
	$(MAKE) uplug-main/Makefile
	$(MAKE) -C uplug-main all install


PACKAGES = $(patsubst %,%.tar.gz,$(shell find . -maxdepth 1 -type d -name 'uplug*'))

dist: $(PACKAGES)

$(PACKAGES): %.tar.gz: %
	$(MAKE) MODE=skip-compile $</Makefile
	$(MAKE) -C $< manifest dist
	mv $</*plug*.tar.gz `ls $</*plug*.tar.gz | sed 's/Uplug/$</'`
	mv $</*plug*.tar.gz .
	$(MAKE) -C $< clean
	-ln -s $<-*.tar.gz $@

%/Makefile:
	cd $(dir $@) && perl Makefile.PL $(MODE)


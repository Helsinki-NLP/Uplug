
MODULES = uplug-main $(wildcard uplug-??) uplug-treetagger uplug-hunalign-dics

ifdef PREFIX
  MAKE_ARGS = PREFIX=${PREFIX}
endif

all test install:
	for m in $(MODULES); do\
		$(MAKE) $$m/Makefile; \
		$(MAKE) -C $$m $@ ${MAKE_ARGS}; \
	done

clean:
	for m in $(MODULES); do\
		$(MAKE) MODE=skip-compile $$m/Makefile; \
		$(MAKE) -C $$m $@; \
	done
	${MAKE} -C uplug-main/doc clean
	${MAKE} -C uplug-main/opt clean
	-rm -fr uplug-treetagger/share/ext/tree-tagger/*
	-find . -name 'Makefile.old' | xargs rm -f
	-find . -name '*.xml.idx' | xargs rm -f
	-find . -name 'META.yml' | xargs rm -f
	-find . -name 'translate.txt' | xargs rm -f
	-find . -name 'runtime' -type d | xargs rm -fr
	-rm -fr uplug-*/inc uplug-*/uplug/inc


install-main:
	$(MAKE) uplug-main/Makefile
	$(MAKE) -C uplug-main all install


PACKAGES = $(patsubst %,%.tar.gz,$(shell find . -maxdepth 1 -type d -name 'uplug*'))

dist: clean packages

packages: $(PACKAGES)

$(PACKAGES): %.tar.gz: %
	$(MAKE) MODE=skip-compile $</Makefile
	$(MAKE) -C $< manifest dist
	if [ ! -e `ls $</*plug*.tar.gz | sed 's/Uplug/$</'` ]; then \
	  mv $</*plug*.tar.gz `ls $</*plug*.tar.gz | sed 's/Uplug/$</'`; \
	fi
	mv $</*plug*.tar.gz .
	$(MAKE) -C $< clean

%/Makefile:
	cd $(dir $@) && perl Makefile.PL $(MODE) ${MAKE_ARGS}


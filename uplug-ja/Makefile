
# install chasen and uplug

VERSION = 0.1

CONTENTS = $(shell ls) 

CHASEN=chasen-2.4.5
DARTS=darts-0.32
IPADIC=ipadic-2.7.0

all test install: $(CHASEN)/Makefile $(IPADIC)/Makefile uplug/Makefile
	which chasen || \
		( ${MAKE} -C $(DARTS) $@ && \
		  ${MAKE} -C $(CHASEN) $@ && \
		  ${MAKE} -C $(IPADIC) $@ )
	${MAKE} -C uplug $@

clean:
	${MAKE} uplug/Makefile
	${MAKE} -C uplug $@
	rm -fr $(DARTS) $(CHASEN) $(IPADIC)

manifest: clean

dist: clean
	rm -f */Makefile.old
	mkdir -p $(notdir $(shell pwd))-$(VERSION)
	mv $(CONTENTS) $(notdir $(shell pwd))-$(VERSION)
	tar -czf $(notdir $(shell pwd))-$(VERSION).tar.gz $(notdir $(shell pwd))-$(VERSION)
	mv $(notdir $(shell pwd))-$(VERSION)/* .
	rmdir $(notdir $(shell pwd))-$(VERSION)







$(DARTS)/Makefile:
	tar -xzf $(DARTS).tar.gz
	cd $(DARTS) && ./configure

# a little hack: make a symbolic link to ../darts/darts.h to make it compile ...

$(CHASEN)/Makefile: $(DARTS)/Makefile 
	tar -xzf $(CHASEN).tar.gz
	( cd $(CHASEN) && ./configure --with-darts=../$(DARTS) )
	( cd $(CHASEN) && ln -s ../$(DARTS)/darts.h . )

# dictionary

$(IPADIC)/Makefile: $(CHASEN)/Makefile 
	tar -xzf $(IPADIC).tar.gz
	( cd $(IPADIC) && \
	  ./configure 	--with-chasen-config=../$(CHASEN) \
			--with-mkchadic=../$(CHASEN)/mkchadic \
			--with-chasenrc-path=/usr/local/etc )

uplug/Makefile: uplug/Makefile.PL
	(cd $(dir $@) && perl Makefile.pl)

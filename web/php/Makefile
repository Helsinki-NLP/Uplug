

#CORPUS = ensvfbell
#LANGPAIR = ensv

###########################################################################
# change the settings below
#
#    UPLUG ........ home directory of your Uplug distribution
#    ALIGN ........ type of word alignment to be run (to create clue DBMs)
#    CORPUS ....... parallel corpus name (without extension '.ces')
#    LANGPAIR ..... language ID pair of your parallele corpus


UPLUG = uplug
ALIGN = basic

CORPUS = $(patsubst %.ces,%,$(wildcard *.ces))
LANGPAIR = $(shell echo '$(CORPUS)' | sed 's/^\(....\).*$$/\1/')

###########################################################################
# you probably don't have to change the settings below

INVLANGPAIR = $(shell echo '$(LANGPAIR)' | sed 's/\(..\)\(..\)/\2\1/');
SENTALIGN = $(CORPUS).ces
SENTALIGNIDS = $(CORPUS).ids
WORDALIGN = $(CORPUS).$(ALIGN)



CONFIG = config.inc
DATADIR = aligned


all: $(DATADIR) $(SENTALIGNIDS) $(WORDALIGN) $(CONFIG)

$(DATADIR):
	mkdir -p $(DATADIR)
	chmod o+w $(DATADIR)
	mkdir -p data/runtime
	chmod o+w data/runtime

$(SENTALIGNIDS): $(SENTALIGN)
	grep '<link ' $(SENTALIGN) | cut -d '"' -f2 > $@
	rm -f config.inc


$(WORDALIGN): $(SENTALIGN)
	$(UPLUG)/uplug align/word/$(ALIGN) -in $(SENTALIGN) -out $(WORDALIGN)


$(CONFIG): %.inc: %.in
	sed 's/%%DATADIR%%/$(DATADIR)/' $< |\
	sed 's/%%IDFILE%%/$(SENTALIGNIDS)/' |\
	sed 's/%%BITEXT%%/$(SENTALIGN)/' |\
	sed 's/%%UPLUG%%/$(UPLUG)/' |\
	sed 's/%%LANGPAIR%%/$(LANGPAIR)/' |\
	sed 's/%%INVLANGPAIR%%/$(INVLANGPAIR)/' > $@


clean:
	rm -f config.inc
	rm -f $(SENTALIGNIDS)
#	rm -f $(WORDALIGN)

test:
	echo $(CORPUS)
	echo $(LANGPAIR)
	echo $(INVLANGPAIR)


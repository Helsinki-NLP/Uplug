#############################################################################
# set the following variables:

# CORPUS ...... name of the corpus (without extension)
# SRCLANG ..... source language identifier (eg. en, sv, ...)
# TRGLANG ..... target language identifier (eg. en, sv, ...)
#
# UPLUG ....... home directory of your Uplug distribution
# ALIGN ....... type of word alignment to be run (to create clue DBMs)


#############################################################################
# set the following variables if necessary:

# SRCXML ...... source language document (default: $(CORPUS)$(SRCLANG).xml)
# TRGXML ...... target language document (default: $(CORPUS)$(TRGLANG).xml)

#############################################################################

UPLUG = uplug
ALIGN = basic


## default: look for a *.ces file in the current directory

# CORPUS = $(patsubst %.ces,%,$(wildcard *.ces))
CORPUS = corpora/1988sven

## default: first two characters of the corpus name (or path) = SRCLANG
## default: characters 3 and 4 of the corpus name (or path) = TRGLANG

#SRCLANG = $(shell echo '$(CORPUS)' | sed 's/^\(..\).*$$/\1/')
#TRGLANG = $(shell echo '$(CORPUS)' | sed 's/^..\(..\).*$$/\1/')

SRCLANG = $(shell echo '$(CORPUS)' | sed 's/^.*\(..\)..$$/\1/')
TRGLANG = $(shell echo '$(CORPUS)' | sed 's/^.*\(..\)$$/\1/')

LANGPAIR = $(SRCLANG)$(TRGLANG)
INVLANGPAIR = $(TRGLANG)$(SRCLANG)

BASENAME = $(shell echo '$(CORPUS)' | sed 's/$(LANGPAIR)//')

#############################################################################

SRCXML = $(BASENAME)$(SRCLANG).xml
TRGXML = $(BASENAME)$(TRGLANG).xml

SRCTXT = $(patsubst %.xml,%.txt,$(SRCXML))
TRGTXT = $(patsubst %.xml,%.txt,$(TRGXML))
ENCODING = iso-8859-1

#############################################################################

SENTALIGN = $(CORPUS).ces
SENTALIGNIDS = $(CORPUS).ids
WORDALIGN = $(CORPUS).$(ALIGN)

#############################################################################


CONFIG = include/config.inc
ISACONFIG = include/config.isa
ICACONFIG = include/config.ica

# DATADIR = $(shell echo '$(CORPUS)' | sed 's|/[^/]*$$||')
DATADIR = $(CORPUS)

# make all .............. make config and data-dirs to run ISA (sentalign)
# make sentalign ........ prepare for ISA (interactice sentence aligner)
# make wordalign ........ run word alignment to make clues for ICA


all: sentalign

sentalign: $(SRCXML) $(TRGXML) $(DATADIR) $(ISACONFIG)

wordalign: $(SENTALIGN) $(SENTALIGNIDS) $(WORDALIGN) $(DATADIR) $(ICACONFIG)


$(DATADIR):
	mkdir -p $(DATADIR)
	chmod o+w $(DATADIR)
	mkdir -p data/runtime
	chmod o+w data/runtime

$(SRCXML):
	$(UPLUG)/uplug pre/basic -ci '$(ENCODING)' -in $(SRCTXT) -out $@

$(TRGXML):
	$(UPLUG)/uplug pre/basic -ci '$(ENCODING)' -in $(TRGTXT) -out $@

$(SENTALIGN): $(SRCXML) $(TRGXML)
	$(UPLUG)/uplug align/sent -src $(SRCXML) -trg $(TRGXML) -out $@

$(SENTALIGNIDS): $(SENTALIGN)
	grep '<link ' $(SENTALIGN) |\
	sed 's/^.* id="//' |\
	cut -d '"' -f1 > $@
	rm -f config.inc


$(WORDALIGN): $(SENTALIGN)
	$(UPLUG)/uplug align/word/$(ALIGN) -in $(SENTALIGN) -out $(WORDALIGN)


$(CONFIG): %.inc: %.in $(SRCXML) $(TRGXML)
	sed 's#%%IDFILE%%#$(SENTALIGNIDS)#' $< |\
	sed 's#%%DATADIR%%#$(DATADIR)#' |\
	sed 's#%%SRCXML%%#$(SRCXML)#' |\
	sed 's#%%TRGXML%%#$(TRGXML)#' |\
	sed 's#%%BITEXT%%#$(SENTALIGN)#' |\
	sed 's#%%UPLUG%%#$(UPLUG)#' |\
	sed 's#%%LANGPAIR%%#$(LANGPAIR)#' |\
	sed 's#%%INVLANGPAIR%%#$(INVLANGPAIR)#' > $@

$(ISACONFIG): %.isa: %.in $(SRCXML) $(TRGXML)
	sed 's#%%IDFILE%%#$(SENTALIGNIDS)#' $< |\
	sed 's#%%DATADIR%%#$(DATADIR)#' |\
	sed 's#%%SRCXML%%#$(SRCXML)#' |\
	sed 's#%%TRGXML%%#$(TRGXML)#' |\
	sed 's#%%BITEXT%%#$(SENTALIGN)#' |\
	sed 's#%%UPLUG%%#$(UPLUG)#' |\
	sed 's#%%LANGPAIR%%#$(LANGPAIR)#' |\
	sed 's#%%INVLANGPAIR%%#$(INVLANGPAIR)#' > $@

$(ICACONFIG): %.ica: %.in $(SRCXML) $(TRGXML)
	sed 's#%%IDFILE%%#$(SENTALIGNIDS)#' $< |\
	sed 's#%%DATADIR%%#$(DATADIR)#' |\
	sed 's#%%SRCXML%%#$(SRCXML)#' |\
	sed 's#%%TRGXML%%#$(TRGXML)#' |\
	sed 's#%%BITEXT%%#$(SENTALIGN)#' |\
	sed 's#%%UPLUG%%#$(UPLUG)#' |\
	sed 's#%%LANGPAIR%%#$(LANGPAIR)#' |\
	sed 's#%%INVLANGPAIR%%#$(INVLANGPAIR)#' > $@

clean:
	rm -f config.inc
	rm -f $(SENTALIGNIDS)
#	rm -f $(WORDALIGN)

test:
	echo $(CORPUS)
	echo $(LANGPAIR)
	echo $(INVLANGPAIR)


#
# USAGE
#
#  make   ...................  make files needed for ISA (sentence alignment) 
#                              with default corpus (1988sven)
#  make sentalign ...........  make ISA files for default corpus
#  make wordalign ...........  make ICA files (word alignment) for default corpus
#  make ALIGN=xx wordalign ..  make ICA files using word alignment config 'xx'
#                              (default is 'basic', check uplug/systems/align/word/
#                               in your Uplug directory for alternatives)
#  make C=cc sentalign ......  make files for ISA for corpus 'cc'
#                              (corpus name should be nnXXYY where 
#                               XX is the ID of the source language (2 characters!)
#                               YY is the ID of the target language (2 characters!)
#                               and nn is some name (without spaces)
#                              the Makefile expects source and target files in
#                              corpora/ with the names 'nnXX.txt' and 'nnYY.txt'
#  make C=cc wordalign ......  make ICA files for corpus 'cc' (same as above)
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Makefile expects Uplug to be installed in ./uplug
# change the UPLUG variable below if this isn't the case
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
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

# PWD = $(shell pwd)

# UPLUG = ${PWD}/uplug
UPLUG = uplug
ALIGN = basic


## default: look for a *.ces file in the current directory

C = 1988sven
# CORPUS = $(patsubst %.ces,%,$(wildcard *.ces))
CORPUS = corpora/$(C)

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


CORPUSDIR = $(shell echo '$(CORPUS)' | sed 's|/[^/]*$$||')
DATADIR = $(CORPUS)

CONFIG = $(DATADIR)/config.inc
ISACONFIG = $(DATADIR)/config.isa
ICACONFIG = $(DATADIR)/config.ica


# make all .............. make config and data-dirs to run ISA (sentalign)
# make sentalign ........ prepare for ISA (interactice sentence aligner)
# make wordalign ........ run word alignment to make clues for ICA


all: sentalign

sentalign: $(SRCXML) $(TRGXML) $(DATADIR) $(CONFIG)
	chmod o+w $(CORPUSDIR)

wordalign: $(DATADIR) $(SENTALIGN) $(SENTALIGNIDS) $(WORDALIGN) $(CONFIG)


$(DATADIR):
	mkdir -p $(DATADIR)
	chmod o+w $(DATADIR)
	mkdir -p $(DATADIR)/data/runtime
	chmod o+w $(DATADIR)/data/runtime

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
	rm -f $(DATADIR)/corpora
	ln -s $(PWD)/corpora $(DATADIR)/
	( cd $(DATADIR);\
	$(UPLUG)/uplug align/word/$(ALIGN) \
	          -in ${PWD}/$(SENTALIGN) \
	          -out $(PWD)/$(WORDALIGN) )

clues: basicclues gizarefined $(CONFIG)

dynamicclues: $(WORDALIGN) $(CONFIG)
	( cd $(DATADIR);\
	$(UPLUG)/uplug align/word/dynamicclues \
	          -in ${PWD}/$(WORDALIGN) )

basicclues: $(SENTALIGN) $(CONFIG)
	rm -f $(DATADIR)/corpora
	ln -s $(PWD)/corpora $(DATADIR)/
	( cd $(DATADIR);\
	$(UPLUG)/uplug align/word/basicclues \
	          -in ${PWD}/$(SENTALIGN) )

gizarefined: $(DATADIR)/giza-refined.links $(CONFIG)
gizaprefix: $(DATADIR)/giza-prefix.links $(CONFIG)
gizapos: $(DATADIR)/giza-pos.links $(CONFIG)

$(DATADIR)/giza-refined.links: $(SENTALIGN)
	rm -f $(DATADIR)/corpora
	ln -s $(PWD)/corpora $(DATADIR)/
	( cd $(DATADIR);\
	$(UPLUG)/uplug align/word/GIZA/giza-word-refined \
	          -in ${PWD}/$(SENTALIGN) \
		  -out $(DATADIR)/giza-refined.links )

$(DATADIR)/giza-pos.links: $(SENTALIGN)
	rm -f $(DATADIR)/corpora
	ln -s $(PWD)/corpora $(DATADIR)/
	( cd $(DATADIR);\
	$(UPLUG)/uplug align/word/GIZA/gizaclue-pos \
	          -in ${PWD}/$(SENTALIGN) \
		  -out $(DATADIR)/giza-pos.links )

$(DATADIR)/giza-prefix.links: $(SENTALIGN)
	rm -f $(DATADIR)/corpora
	ln -s $(PWD)/corpora $(DATADIR)/
	( cd $(DATADIR);\
	$(UPLUG)/uplug align/word/GIZA/gizaclue-word-prefix \
	          -in ${PWD}/$(SENTALIGN) \
		  -out $(DATADIR)/giza-pos.links )


$(CONFIG): $(DATADIR)/%.inc: include/%.in $(SRCXML) $(TRGXML)
	sed 's#%%IDFILE%%#$(SENTALIGNIDS)#' $< |\
	sed 's#%%DATADIR%%#$(DATADIR)#' |\
	sed 's#%%SRCXML%%#$(SRCXML)#' |\
	sed 's#%%TRGXML%%#$(TRGXML)#' |\
	sed 's#%%BITEXT%%#$(SENTALIGN)#' |\
	sed 's#%%UPLUG%%#$(UPLUG)#' |\
	sed 's#%%LANGPAIR%%#$(LANGPAIR)#' |\
	sed 's#%%INVLANGPAIR%%#$(INVLANGPAIR)#' > $@

$(ISACONFIG): $(DATADIR)/%.isa: include/%.in $(SRCXML) $(TRGXML)
	sed 's#%%IDFILE%%#$(SENTALIGNIDS)#' $< |\
	sed 's#%%DATADIR%%#$(DATADIR)#' |\
	sed 's#%%SRCXML%%#$(SRCXML)#' |\
	sed 's#%%TRGXML%%#$(TRGXML)#' |\
	sed 's#%%BITEXT%%#$(SENTALIGN)#' |\
	sed 's#%%UPLUG%%#$(UPLUG)#' |\
	sed 's#%%LANGPAIR%%#$(LANGPAIR)#' |\
	sed 's#%%INVLANGPAIR%%#$(INVLANGPAIR)#' > $@

$(ICACONFIG):$(DATADIR)/%.ica: include/%.in $(SRCXML) $(TRGXML)
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


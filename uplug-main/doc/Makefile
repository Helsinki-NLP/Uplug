
# 'make wiki' requires Pod::Simple::Wiki from cpan

modulehome = ../lib
modules = Uplug.pm Uplug/Config.pm Uplug/IO.pm Uplug/IO/Any.pm

binhome = ..
scripts = uplug

textdoc = $(patsubst %.pm,%.txt,$(modules))
htmldoc = $(patsubst %.pm,%.html,$(modules))
wikidoc = $(patsubst %.pm,wiki/%.wiki,$(modules))

textdocbin = $(patsubst %,%.txt,$(scripts))
htmldocbin = $(patsubst %,%.html,$(scripts))
wikidocbin = $(patsubst %,wiki/%.wiki,$(scripts))

# textdoc = $(shell echo "$(modules)" | sed 's|Lingua/||g' | tr '/' '-' | sed 's/.pm/.txt/g')


all: text html

clean:
	rm -f $(textdoc) $(textdocbin) index.txt
	rm -f $(htmldoc) $(htmldocbin) index.html
	rm -f $(wikidoc) $(wikidocbin) wiki/Home.wiki
	rm -f *.tmp
	rm -fr wiki Uplug

text: index.txt $(textdoc) $(textdocbin)
html: index.html $(htmldoc) $(htmldocbin)
wiki: $(wikidoc) $(wikidocbin) wiki/Home.wiki

index.html: index.pod
	pod2html --htmlroot='/~'`whoami` \
		--css='/~'`whoami`/css/pod.css \
		index.pod > index.html

index.txt: index.pod
	pod2text index.pod > index.txt

$(textdoc): %.txt: $(modulehome)/%.pm
	mkdir -p `dirname $@`
	pod2text $< > $@

$(textdocbin): %.txt: $(binhome)/%
	mkdir -p `dirname $@`
	pod2text $< > $@


$(htmldoc): %.html: $(modulehome)/%.pm
	mkdir -p `dirname $@`
	pod2html --htmlroot='/~'`whoami` \
		--css='/~'`whoami`/css/pod.css \
		$(modulehome)/$< > $@


$(htmldocbin): %.html: $(binhome)/%
	mkdir -p `dirname $@`
	pod2html --htmlroot='/~'`whoami` \
		--css='/~'`whoami`/css/pod.css \
		$(modulehome)/$< > $@


$(wikidoc): wiki/%.wiki: $(modulehome)/%.pm
	mkdir -p `dirname $@`
	pod2wiki --style=moinmoin --encoding=utf8 \
		$(modulehome)/$< > $@

$(wikidocbin): wiki/%.wiki: $(binhome)/%
	mkdir -p `dirname $@`
	pod2wiki --style=moinmoin --encoding=utf8 \
		$(binhome)/$< > $@

wiki/Home.wiki: index.pod
	mkdir -p `dirname $@`
	pod2wiki --style=moinmoin --encoding=utf8 $< > $@
	@echo "\n== More Information ==\n" >> $@
	find . -name '*.wiki'  | sort | grep -v 'Home.wiki' |\
	sed 's#^\.\/# * [[#;s#\.wiki#.wiki]]#;s#wiki/##' >> $@

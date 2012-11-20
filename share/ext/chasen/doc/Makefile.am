docdir = $(pkgdatadir)/doc
TEX =  manual.tex manual-j.tex  
PDF =  manual.pdf manual-j.pdf
EXTRA_DIST = $(TEX) $(PDF)
SUFFIXES= .tex .dvi .pdf

.tex.dvi:
	platex $<
	platex $<

.dvi.pdf:
	dvipdfm $<

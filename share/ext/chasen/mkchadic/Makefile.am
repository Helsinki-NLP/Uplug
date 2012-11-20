INCLUDES  = -I.. -I$(srcdir)/../lib
LDADD = $(top_builddir)/lib/libchasen.la
DEFS = -DRCPATH=\""$(RCPATH)\"" @DEFS@

pkglibexecdir = ${libexecdir}/chasen
pkglibexec_PROGRAMS = convdic makeint makemat mkary pattool sortdic convary

convdic_SOURCES =  convdic.c
makeint_SOURCES = trans.c makeint.c 
makemat_SOURCES = makemat.c
mkary_SOURCES = mkary.c
pattool_SOURCES = interface.c
sortdic_SOURCES = sortdic.c
convary_SOURCES = convary.c

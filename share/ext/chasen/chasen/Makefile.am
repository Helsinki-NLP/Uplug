bin_PROGRAMS = chasen
noinst_PROGRAMS = chasmpl

INCLUDES  = -I.. -I$(srcdir)/../lib
LDADD = $(top_builddir)/lib/libchasen.la

chasen_SOURCES = chasen.c  client.c  server.c
chasmpl_SOURCES = chasmpl.c

DEFS = -DRCPATH=\""$(RCPATH)\"" @DEFS@

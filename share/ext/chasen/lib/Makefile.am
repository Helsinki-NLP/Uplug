include_HEADERS = chasen.h
lib_LTLIBRARIES = libchasen.la

libchasen_la_SOURCES = 	chadic.h chalib.c chalib.h chfile.c connect.c \
			getid.c getopt.c grammar.c init.c iotool.c \
			jfgets.c katuyou.c lisp.c tokenizer.c parse.c \
			pat.c pat.h patfile.c print.c select.c sufary.h \
			zentohan.c mmap.c dic.c tokenizer.h htobe.c htobe.h

libchasen_la_LDFLAGS = -version-info $(LTVERSION)

INCLUDES  = -I.. 
DEFS = -DRCPATH="\"$(RCPATH)\"" @DEFS@

dll:
	$(CC) -shared -Wl,--output-def,libchasen.def -o libchasen.dll *.o
	i386-mingw32msvc-strip libchasen.dll

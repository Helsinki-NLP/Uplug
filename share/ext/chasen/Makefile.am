AUTOMAKE_OPTIONS = 1.4 no-dependencies

SUBDIRS = doc prolog lib chasen mkchadic
EXTRA_DIRS = perl

EXTRA_DIST = README-ja INSTALL-ja NEWS-ja chasen.spec
bin_SCRIPTS = chasen-config

dist-hook:
	for subdir in $(EXTRA_DIRS); do \
	    cp -rp $$subdir $(distdir)/$$subdir; \
	    rm -f $(distdir)/$$subdir/*~; \
	    rm -f $(distdir)/$$subdir/*.{bak,orig}; \
	    rm -f $(distdir)/$$subdir/.cvsignore; \
	    rm -f $(distdir)/$$subdir/autogen.sh; \
	    rm -rf $(distdir)/$$subdir/CVS; \
	    rm -rf $(distdir)/$$subdir/*/CVS; \
	done

rpm: dist	
	rpm -ta @PACKAGE@-@VERSION@.tar.gz

win:
	$(MAKE) distclean
	env OBJDUMP=i386-mingw32msvc-objdump AS=i386-mingw32msvc-as \
	AR=i386-mingw32msvc-ar RANLIB=i386-mingw32msvc-ranlib \
	CXX=i386-mingw32msvc-g++ CC=i386-mingw32msvc-gcc \
	NM=i386-mingw32msvc-nm DLLTOOL=i386-mingw32msvc-dlltool \
	./configure --disable-shared --host=i386-pc-mingw32 --target=i386-pc-mingw32
	nkf -s lib/chadic.h > lib/chadic-sjis.h
	cp -f lib/chadic.h lib/chadic-euc.h
	mv -f lib/chadic-sjis.h lib/chadic.h
	$(MAKE) CFLAGS+=-DNO_SERVER CFLAGS+=-DCHASEN_DLL_EXPORT LIBS=-lwsock32
	(cd lib; $(MAKE) dll)
	mv -f lib/chadic-euc.h lib/chadic.h

win-dic:
	tar zxfv ipadic-sjis*.tar.gz
	cd ipadic-sjis* && ./configure --with-mkchadic="wine -- ../mkchadic" --with-chasenrc-path=../@PACKAGE@-@VERSION@/etc/chasenrc --with-dicdir=../@PACKAGE@-@VERSION@/share/chasen/dic
	cd ipadic-sjis* && make

win-dist:
	rm -f @PACKAGE@-@VERSION@.zip
	rm -rf @PACKAGE@-@VERSION@
	$(MAKE) prefix=`pwd`/@PACKAGE@-@VERSION@ install
	rm -fr ./@PACKAGE@-@VERSION@/lib/libchasen*
	rm -fr ./@PACKAGE@-@VERSION@/bin/chasen-config
	cp -f lib/libchasen.dll ./@PACKAGE@-@VERSION@/lib
	cp -f lib/libchasen.def ./@PACKAGE@-@VERSION@/lib
	mkdir ./@PACKAGE@-@VERSION@/etc	
	cd ipadic-sjis* && make prefix=../@PACKAGE@-@VERSION@/ install
	nkf -s -c ./@PACKAGE@-@VERSION@/etc/chasenrc | sed -e 's#/#\\#g' -e 's#\.\.#c:Program Files\\#g' -e 's#-@VERSION@##' >./@PACKAGE@-@VERSION@/etc/chasenrc.new
	mv -f ./@PACKAGE@-@VERSION@/etc/chasenrc.new ./@PACKAGE@-@VERSION@/etc/chasenrc
	zip -r @PACKAGE@-@VERSION@.zip @PACKAGE@-@VERSION@
	rm -fr @PACKAGE@-@VERSION@

##Bug in automake: Can't use `if MAINTAINER_MODE'
@MAINTAINER_MODE_TRUE@include $(srcdir)/maintMakefile

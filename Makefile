

# make all ---> make a release with version = ${VERSION}


VERSION = 0.2.0d
TODAY = `date`

all: uplug-${VERSION}.tar.gz

uplug-${VERSION}.tar.gz:
	mkdir /tmp/uplug
	cp -R * /tmp/uplug/
	find /tmp/uplug -name '*~' -exec rm {} \;
	find /tmp/uplug -type d -name 'CVS' | xargs rm -fr
	rm -f /tmp/uplug/Makefile
	sed "s/VERSION = .*$$/VERSION = '$(VERSION)';/" Uplug.pm > /tmp/uplug/Uplug.pm |\
	(cd /tmp;tar -czf $@ uplug)
	mv /tmp/$@ .
	rm -fr /tmp/uplug

clean:
	rm -f uplug-${VERSION}.tar.gz
	rm -fr /tmp/uplug

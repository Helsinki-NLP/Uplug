

# make all ---> make a release with version = ${VERSION}


VERSION = 0.1.9c
TODAY = `date`

all: uplug-${VERSION}.zip

uplug-${VERSION}.zip:
	mkdir /tmp/uplug
	cp -R * /tmp/uplug/
	find /tmp/uplug -name '*~' -exec rm {} \;
	find /tmp/uplug -type d -name 'CVS' | xargs rm -fr
	rm -f /tmp/uplug/Makefile
	sed "s/VERSION = .*$$/VERSION = $(VERSION)" Uplug.pm > /tmp/uplug/Uplug.php |\
	(cd /tmp;zip -r $@ uplug)
	mv /tmp/$@ .
	rm -fr /tmp/uplug

clean:
	rm -f ppp-blog-${VERSION}.zip
	rm -fr /tmp/uplug

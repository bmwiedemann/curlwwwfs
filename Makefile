
build:
	echo this is perl - nothing to compile

install:
	mkdir -p ${DESTDIR}/usr/bin
	install -m 755 -p curlwwwfs.pl ${DESTDIR}/usr/bin/curlwwwfs
	echo "also requires perl-Fuse"

check: test
test:
	cd tests ; make

tar:
	tar --exclude=.*.swp --exclude=.git --exclude=old -czf ../curlwwwfs-1.tar.gz ../curlwwwfs

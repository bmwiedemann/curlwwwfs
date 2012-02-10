
test:
#dd if=/dev/zero of=/home/bernhard/public_html/testz bs=1M seek=10 count=1
	mkdir -p mnt
	perl -c curlwwwfs.pl
	./curlwwwfs.pl mnt&
	sleep 2
#	-ls -la .
	-ls -la mnt
	-stat mnt/testz
	-du mnt/testz
	-ls -la mnt/dir1
	-cat mnt/dir1/file
	-cat mnt/testmissing
	-ls mnt/testmissing2
	-cat mnt/testforbidden
	-ls mnt/testforbidden2
	#-md5sum mnt/testz ~/public_html/testz
	fusermount -u mnt

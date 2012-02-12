LANG=C
username=$(shell whoami)
testdirname=curlwwwfstest
testdir=${HOME}/public_html/${testdirname}
# assumes apache configured with userdir
testURL=http://localhost/~${username}/${testdirname}

all: prepare testrunprepare tests testruncleanup

prepare:
	-make clean
	mkdir -p ${testdir}/dir1 ${testdir}/dir2
	echo abccontent > ${testdir}/abc
	dd if=/dev/urandom of=${testdir}/random103 bs=103k count=1
	dd if=/dev/urandom of=${testdir}/random500 bs=512k count=1
	umask 77 ; echo forbidden > ${testdir}/forbiddenfile ; mkdir ${testdir}/forbiddendir

testrunprepare:
	mkdir -p mnt
	../curlwwwfs.pl ${testURL} mnt &
	sleep 2;

testruncleanup:
	-fusermount -u mnt
	-rmdir mnt

clean: testruncleanup
	rm -rf ${testdir}


tests: test1 test2 test3 test4
test1:
	diff ${testdir}/abc mnt/abc
	diff ${testdir}/random103 mnt/random103
	diff ${testdir}/random500 mnt/random500

test2:
	cat mnt/forbiddenfile 2>&1 | grep "cat: mnt/forbiddenfile: Permission denied"
	cat mnt/forbiddendir 2>&1 | grep "cat: mnt/forbiddendir: Permission denied"
	ls mnt/forbiddendir 2>&1 | grep "ls: cannot access mnt/forbiddendir: Permission denied"
	cat mnt/missingfile 2>&1 | grep "cat: mnt/missingfile: No such file or directory"
	ls -l mnt/missingdir 2>&1 | grep "ls: cannot access mnt/missingdir: No such file or directory"

test3:
	#ls -a mnt | cat > ref3
	ls -a mnt | diff - ref3

test4:
	du mnt/random500 | grep 512


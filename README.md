##Installation

curlwwwfs requires the Fuse module, which you can get for openSUSE and SLE with

    OneClickInstallUI http://multiymp.zq1.de/devel:languages:perl/perl-Fuse
    # and additionally you need
    zypper -n in make perl-libwww-perl
    make install


##Usage

    mkdir mnt
    curlwwwfs http://lsmod.de/bootcd/ mnt

This will remain running in the foreground.
You can add a & to send it into background.

When you do not need the mount anymore, you unmount it with

    fusermount -u mnt

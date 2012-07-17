#!/usr/bin/perl -w
# curlwwwfs allows users to mount HTTP directories
# Copyright (C) 2012  Bernhard M. Wiedemann

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

# OneClickInstallUI http://i.opensu.se/devel:languages:perl/perl-Fuse
my $debug=0;

use strict;
use POSIX;
use Fuse;
use LWP::UserAgent;
use Time::Local;
sub usage() { die "usage: $0 URL MNT\n";}
my $baseurl=shift || usage;
my $mnt=shift || usage;
my $ua=LWP::UserAgent->new(parse_head=>0, timeout=>9, keep_alive=>4);
$ua->agent("curlwwwfs");
our %cache;
our %month=qw(Jan 1 Feb 2 Mar 3 Apr 4 May 5 Jun 6 Jul 7 Aug 8 Sep 9 Oct 10 Nov 11 Dec 12);

sub diag{return unless $debug; print @_} # debug

sub path2url($)
{
	my $url="$baseurl$_[0]";
}

# input HTTP result code (e.g. 404)
# output: fuse return code - zero on success
sub checkerror($)
{ my($code)=shift;
	if($code==403) {return -1*EACCES}
	if($code==404) {return -1*ENOENT}
	if($code>=400) {return -1*EIO}
	return 0;
}

sub my_getdir($)
{ my($f)=@_;
	$f=~s{[^/]$}{$&/}; # add trailing slash
	my $url=path2url($f);
	diag "getdir: $url\n";
	my $r = $ua->get($url);
	if(my $e=checkerror($r->code)) {return $e}
	my $c=$r->content;
	my @ref;
	foreach my $line ($c=~m/<a href="([^"]+".*)/gi) {
		next unless $line=~m{^([^"]+)">[^<]+</a>.*(\d{2})-(\w{3})-(\d{4})\s+(\d{2}):(\d{2})\s+(\S+)}i;
		my($ref,$day,$mon,$year,$hour,$min,$size)=($1,$2,$3,$4,$5,$6,$7);
		my $d=($ref=~s{/$}{});
		next unless $ref=~m/^[^?\/]+$/; # filter out dynamic links and upward links
		my $path="$f$ref";
		#diag "cache: $path,$day,$mon,$year,$hour,$min,$size\n";
	   	$cache{$path}->{mtime}=timegm(0, $min, $hour, $day, $month{$mon}-1, $year);
		$cache{$path}->{size}=$size if($size=~m/^\d+$/);
	   	$cache{$path}->{dir}=$d;
		if($d) {$cache{$path}->{size}=0}
		push(@ref,$ref);
	}
	return (".","..",@ref,0);
}

sub my_getattr($)
{ my($f)=@_;
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=(0,0);
	my $isfile;
	$cache{$f}||={};
	my $c=$cache{$f};
	$nlink=1;
	$uid=$<;
	($gid)=split / /,$(;
	$size=0;
	$rdev=0;
	$atime=time;
	$mtime=$atime;
	if(!$c || !defined($c->{size})) { # need to get size from headers - e.g. when apache said 123M before but we need exact sizes for read to work
		my $url=path2url($f);
		my $code=$c->{code};
		my $r;
		if(!$code) {
			$r = $ua->head($url);
			$c->{code}=$code=$r->code;
			$c->{headers}=$r;
			#diag("code: $code\n");
		} else {$r=$c->{headers}}
		if(my $e=checkerror($r->code)) {return $e}
		$c->{size}=$r->header("Content-Length");
		my $type=$r->header("Content-Type");
		if(!defined($c->{size}) && $type=~m{text/html}) {$c->{dir}=1; }
		my $lm=$r->header("Last-Modified");
		if($lm && $lm=~m/(\d{2}) (\w{3}) (\d{4})\s+(\d{2}):(\d{2}):(\d{2})/) {
	   		$c->{mtime}=timegm($6, $5, $4, $1, $month{$2}-1, $3);
			diag "mtime: $mtime\n";
		}
	}
	if($c) {
		$size=$c->{size};
		$mtime=$c->{mtime}||time;
		$isfile=1;
		$mode=0100644; # file
	   	if($c->{dir}) {
			$mode=0040755; # dir
			$isfile=0;
		}
	}
	$size||=0;
	$ctime=$mtime;
	$blksize=512;
	$blocks=int(($size+$blksize-1)/$blksize);
	diag "$dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks\n";
    return ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks);
}

sub my_read($)
{ my($f, $size, $offs)=@_;
	my $endoffs=$offs+$size-1;
	my $url=path2url($f);
	diag "read: $url $f, $size, $offs\n";
	my $r = $ua->get($url, "Range"=>"bytes=$offs-$endoffs");
	my $c=$r->content;
	diag $r->status_line;
	if($r->code==416) {return ""}
	if(my $e=checkerror($r->code)) {return $e}
	return $c;
}

#my $response = $ua->get("http://localhost/~bernhard/");
#print $response->status_line, $response->content;
#exit 0;
Fuse::main(
	debug=>$debug,
	mountpoint=>$mnt,
	getdir=>\&my_getdir,
	getattr=>\&my_getattr,
	read=>\&my_read,
);

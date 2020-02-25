#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;

my $lockfile = "/tmp/autotar";
my $sourcedir;
my $destdir;
my $group;
my $dryrun = 0;
my $processors = 1;
my $memory = 100;

sub timestamp() {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
        my $now = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec);
        return $now;
}

sub archive {
        my $source=$_[0];
        my $dest=$_[1];
        my $destfile=$source;
        $destfile=~ s/_ready$//;
        $destfile="$destfile.tar.bz2";
	my $cmd = "tar -cv $source 2> $dest/$destfile.files | pbzip2 -c -p$processors -m$memory > $dest/$destfile";
        print timestamp() . " Command: $cmd\n";
        if (!$dryrun) {
                system($cmd);
		system("sed -i 's/\\/\$//g' $dest/$destfile.files");
                system("find $source -name '*' >$source.findtest.txt");

                unless(-s "$source.findtest.txt" and -s "$dest/$destfile.files") {
                        die timestamp() . " $source.findtest.txt or $source.tartest.txt does not exist or has a zero size\n";
                }
                if(`diff $dest/$destfile.files $source.findtest.txt`) {
                        die timestamp() . " Tar file and directory do not match\n";
                }
                else {
                        print timestamp() . " Tar file sucessfully verified\n";
                        system("mv $source* archived/");
                        system("chgrp $group $sourcedir/archived/*.txt");
                }
        }
}

sub help() {
        print "Usage\n";
        print "--sourcedir		Source Directory\n";
        print "--destdir		Destination Directory\n";
        print "--group			Group to set archive files to\n";
	print "-p,--processors		Number of Processors (Default 1)\n";
	print "-m,--memory		Amount of memory to use in MB (Default 100MB)\n";
        print "--dry-run		Output commands only\n";
        print "-h,--help		This help\n";
        print "Source Directories must have _ready to be archived\n";
        exit 0;

}


GetOptions(
	"h|help"		=> sub { help() },
	"sourcedir=s"		=> \$sourcedir,
	"destdir=s"		=> \$destdir,
	"group=s"		=> \$group,
	"p|processors=i"	=> \$processors,
	"m|memory=i"		=> \$memory,
	"dry-run"		=> \$dryrun,
);

unless (defined $sourcedir) {
	die "Must specify source directory\n";
}
unless (defined $destdir) {
	die "Must specify destination directory\n";

}
unless (defined $group) {
	die "Must specify group\n";
}


if(-e $lockfile) {
	die "Autotar appears to be already running or a stale lockfile is present in $lockfile\n";
}
else {
	open LOCK, ">$lockfile" or die "Cannot create lock file\n";;
	close LOCK;
}

chdir($sourcedir) or die "Cannot change to $sourcedir\n";
opendir(DIRECTORY,'.') or die "Cannot open main directory $sourcedir\n";
foreach my $member (grep !/^\./, readdir DIRECTORY){
	print "$member\n";
	if($member=~/_ready$/){
		if(-d $member){
			print timestamp() . " Archiving $member\n";
			archive($member, $destdir);
		}
	}
}

unlink $lockfile or die "Lockfile appears to be removed previously\n";



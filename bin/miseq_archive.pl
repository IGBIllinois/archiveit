#!/usr/bin/env perl

use Getopt::Long;
use File::Copy;
use File::Glob 'bsd_glob';
use warnings;

$result=GetOptions("dir=s"		=> \$topdir,
		   "days=i"		=> \$daysforold,
		   "dest=s"		=> \$dest,
		   "exclude=s"		=> \$exclude,
		   "user=s"		=> \$user,
		   "group=s"		=> \$group,
		   "lock=s"		=> \$lockfile);

unless(defined $topdir){
  $topdir='.';
}

unless(defined $daysforold){
  $daysforold=180;
}

unless(defined $lockfile){
  $lockfile="/var/run/miseq";
}

if(defined $user){
  $user=getpwnam($user) or die "$user does not exist\n";
}

if(defined $group){
  $group=getgrnam($group) or die "$group does not exist\n";
}

if(-e $lockfile){
  die "$lockfile already exists, it is possible that this script is already running on this data or the previous run failed\n";
}else{
  open LOCK, ">$lockfile" or die "Cannot create lock file\n";
  close LOCK;
}

if(!defined $dest){
  die "You must define a destination for the archive\n";
}elsif(! -d $dest){
  die "The destination directory $dest does not exist\n";
}

if(-d "$topdir/archived"){
  warn "archived directory already in place, please make sure last archive was finished correctly\n";
}else{
  mkdir "$topdir/archived" or die "unable to make archived drectory $topdir/archived\n";
}

sub prune_pattern {
  my $pattern=shift @_;
  my $entry=shift @_;
  if($pattern eq "miseq"){
    return " -path '$entry/Thumbnail_Images' -o -path '$entry/Logs' -o -path '$entry/Config' -o -path '$entry/Recipe' -o -path '$entry/PeriodicSaveRates' -o -path '$entry/Unaligned*/Basecall*/Plots' -o -path '$entry/Unaligned*/Basecall*/Matrix' -o -path '$entry/Unaligned*/Basecall*/Phasing' -o -path '$entry/Unaligned*/Basecall*/SignalMeans' -o -path '$entry/Unaligned*/Basecall/Temp' -o -path '$entry/Data/Intensities/L001' -o -path '$entry/Data/Intensities/BaseCalls/L001' -o -path '$entry/Images' -o -path '$entry/Data/TileStatus' -o -path '$entry/Data/Intensities/BaseCalls/Matrix' -o -path '$entry/Data/Intensities/BaseCalls/Phasing' -o -path '$entry/Unaligned*/Temp' -o -path '$entry/Unaligned*/Reports/html' ";
  }else{
    die "Pattern $pattern is not defined\n";
  }
}

sub tar_pattern {
  my $pattern=shift @_;
  my $entry=shift @_;
  if($pattern eq "miseq"){
   return " --exclude='$entry/Thumbnail_Images' --exclude='$entry/Logs' --exclude='$entry/Config' --exclude='$entry/Recipe' --exclude='$entry/PeriodicSaveRates' --exclude='$entry/Unaligned*/Basecall*/Plots' --exclude='$entry/Unaligned*/Basecall*/Matrix' --exclude='$entry/Unaligned*/Basecall*/Phasing' --exclude='$entry/Unaligned*/Basecall*/SignalMeans' --exclude='$entry/Unaligned*/Basecall/Temp' --exclude='$entry/Data/Intensities/L001' --exclude='$entry/Data/Intensities/BaseCalls/L001' --exclude='$entry/Images' --exclude='$entry/Data/TileStatus' --exclude='$entry/Data/Intensities/BaseCalls/Matrix' --exclude='$entry/Data/Intensities/BaseCalls/Phasing' --exclude='$entry/Unaligned*/Temp' --exclude='$entry/Unaligned*/Reports/html' ";
  }else{
    die "Pattern $pattern is not defined\n";
  }
}

$escapetop=$topdir;
$escapetop=~s/\//\\\//g;

opendir(TOP, $topdir) or die "unable to open directory $topdir\n";
while($entry=readdir(TOP)){
  if($entry eq '.' or $entry eq '..' or $entry eq 'archived'){
    print "skip directory $entry\n";
  }elsif(-d "$topdir/$entry"){
    $tmpstring="$topdir/$entry";
    $tmpstring=~s/\s/\\ /g;
    $youngfile=`find \"$topdir/$entry\" -type f -printf '\%T\@ \%p\n' | sort -n | tail -1 | cut -f2- -d\" \"`;
    chomp $youngfile;
    $modtime=int(-M $youngfile) or warn "$topdir/$entry appears to not have any files, is it empty?\n";
    if($modtime>$daysforold){
      print "archive $entry, no files changed in $modtime days\n";
      if(-e "$dest/$entry.tar.bz2"){
	die "archive target file already exists $dest/$entry.tar.bz2\n";
      }
      if(-e "$topdir/$entry.tartest.txt"){
	die "tartest file already exists $entry.tartest.txt\nDid archive script crash?\n";
      }
      if(-e "$topdir/$entry.findtest.txt"){
	die "tartest file already exists $entry.findtest.txt\nDid archive script crash?\n";
      }
      system("find '$topdir/$entry' -name '*' \\( ".prune_pattern($exclude, "$topdir/$entry")." \\) -prune -o -print|sed 's/^$escapetop\\\///'>'$topdir/$entry.findtest.txt'");
      print "find '$topdir/$entry' -name '*' \\( ". prune_pattern($exclude, "$topdir/$entry")." \\) -prune -o -print|sed 's/^$escapetop\\\///'>'$topdir/$entry.findtest.txt'\n";
      system("tar -C '$topdir' -cjvf '$dest/$entry.tar.bz2'  ".tar_pattern($exclude, "$entry")." '$entry'   |sed 's/\\/\$//' >'$topdir/$entry.tartest.txt'");
      #print "tar -C $topdir -cjvf $dest/$entry.tar.bz2  ".tar_pattern($exclude, "$entry")." $entry   |sed 's/\\/\$//' >$topdir/$entry.tartest.txt\n";
      if(`diff '$topdir/$entry.tartest.txt' '$topdir/$entry.findtest.txt'`){
	die "tar file and directory do not match\n";
      }else{
	if(-z "$topdir/$entry.findtest.txt"){
	  die "tar file or directory $topdir/$entry.findtest.txt appears to be empty\n";
	}
	print "tar file sucessfully verified\n";
#problem moving files here
	#system("mv '$topdir/$entry*' '$topdir/archived/'");
	move("$topdir/$entry.findtest.txt", "$topdir/archived/") or die "fail moving $topdir/$entry.findtest.txt\n";
	move("$topdir/$entry.tartest.txt", "$topdir/archived/") or die "fail moving $topdir/$entry.tartest.txt\n";
	move("$topdir/$entry/", "$topdir/archived/$entry") or die "fail moving $topdir/$entry/ to $topdir/archived/$entry\n";
	#move "$_", "$topdir/archived/" or die "fail moving $topdir/$_ to $topdir/archived/$_\n" for bsd_glob "$topdir/$entry*.txt";
	#system("cp '$topdir/archived/$entry*.txt' '$dest'");
	copy("$topdir/archived/$entry.findtest.txt", $dest) or die "fail copying $topdir/archived/$entry.findtest.txt\n";
	copy("$topdir/archived/$entry.tartest.txt", $dest) or die "fail copying $topdir/archived/$entry.tartest.txt\n";
	if(defined $group){
	  chown -1,$group,"$dest/$entry.tar.bz2" or die "could not change group of $dest/$entry.tar.bz2\n";
	  chown -1,$group,"$dest/$entry.findtest.txt" or die "could not change group of $dest/$entry.findtest.txt\n";
	  chown -1,$group,"$dest/$entry.tartest.txt" or die "could not change group of $dest/$entry.tartest.txt\n";
	}
	if(defined $user){
	  chown $user,-1,"$dest/$entry.tar.bz2" or die "could not change ownership of $dest/$entry.tar.bz2\n";;
	  chown $user,-1,"$dest/$entry.findtest.txt" or die "could not change ownership of $dest/$entry.findtest.txt\n";
	  chown $user,-1,"$dest/$entry.tartest.txt" or die "could not change ownership of $dest/$entry.tartest.txt\n";
	}
      }
    }else{
      print "not archiving $entry\n";
    }
  }else{
    warn "$entry is not a directory and was not archived\n";
  }
}
close(TOP);

unlink $lockfile or die "Lockfile appears to be removed previously\n";

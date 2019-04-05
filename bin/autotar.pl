#!/usr/bin/perl

$sourcedir='/storage';
#$sourcedir='/oldga/GA3';
$destdir='/archive/CBC/HiSeq';
#$dir='120307_SN411_0255_BD0LJNACXX_Groenen1_Groenen2_ready';
#$dir='120315_SN330_0181_AD0LKTACXX_Groenen_2_3_4_ready';
#$dir='120320_SN411_0256_AC0DYGACXX_Groenen_3_4_ready';
$lockfile="/var/run/autotar";

if(-e $lockfile){
  die "Autotar appears to be already running or a stale lockfile is present in $lockfile\n";
}else{
  open LOCK, ">$lockfile" or die "Cannot creat lock file\n";;
  close LOCK;
}


chdir($sourcedir) or die "cannot change to $sourcedir\n";
opendir(DIRECTORY,'.') or die "Cannot open main directory $directory\n";
foreach my $member (grep !/^\./, readdir DIRECTORY){
  #print "$member\n";
  if($member=~/_ready$/){
    if(-d $member){
      print "Archiving $member\n";
      archive($member, $destdir);
      #die "exiting program after one directory\n";
    }
  }
}

unlink $lockfile or die "Lockfile appears to be removed previously\n";

sub archive {
  my $source=@_[0];
  my $dest=@_[1];
  my $destfile=$source;
  $destfile=~ s/_ready$//;
  #$destfile="$destfile.tar.gz";
  $destfile="$destfile.tar.bz2";
  #print "tar -cvf $dest/$destfile $source |sed 's/\\/\$//' >$source.tartest.txt\n";
  system("tar -czvf $dest/$destfile $source |sed 's/\\/\$//' >$source.tartest.txt");
  #system("tar -cvzf $dest/$destfile $source |sed 's/\\/\$//' >$source.tartest.txt");
  #print "find $source -name '*' >$source.findtest.txt\n";
  system("find $source -name '*' >$source.findtest.txt");
  unless(-s "$source.findtest.txt" and -s "$source.tartest.txt"){
    die "$source.findtest.txt or $source.tartest.txt does not exist or has a zero size\n";
  }
  if(`diff $source.tartest.txt $source.findtest.txt`){
    die "tar file and directory do not match\n";
  }else{
    print "tar file sucessfully verified\n";
    system("mv $source* archived/");
    system("chgrp develope $sourcedir/archived/*.txt");
  }
}

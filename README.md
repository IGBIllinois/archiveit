# archiveit
Active Archive Scripts
* Saves data to the Active Archive system [https://help.igb.illinois.edu/Active_Archive]
* Automatically compresses the directories

## Requirements
* tar
* pbzip2

## autotar.pl
* Used to archive HiSeq runs
```
Usage
--sourcedir		Source Directory
--destdir		Destination Directory
--group			Group to set archive files to
--dry-run		Output commands only
-h,--help			This help
Source Directories must have _ready to be archived
```

## miseq_archive.pl
* Used to archive MiSeqs runs

## archiveit.py
* Another Archive script

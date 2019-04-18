#!/usr/bin/env python

import argparse
import os
import ntpath
import pwd
import grp
import re
from shutil import copyfile

parser=argparse.ArgumentParser(description='Copy files to another directory, changing the group name')
parser.add_argument('-d','--dir',dest='dir',help='path of directory to copy data to',type=str, required=True)
parser.add_argument('-g','--group',dest='group',help='group to own the file once copied, defaults to group of the directory specified',type=str)
parser.add_argument('-f','--files',dest='files',help='files to move',nargs='*', required=True)
args=parser.parse_args()

#make sure the destination is there
if not os.path.isdir(args.dir):
  print("Error:  Destination directory does not exist.")
  quit()

#make sure source file(s) is/are there
for filename in args.files:
  if not os.path.isfile(filename):
    print("file %s does not exist or is not a file" % filename)
    quit()

#check if any of those files exist in destination
for filename in args.files:
  if os.path.exists(args.dir+'/'+ntpath.basename(filename)):
    print("Error:  Filename %s exists in %s" % (ntpath.basename(filename),args.dir))
    quit()

#if group is not specified, fetch it from target directory
if args.group is None:
  stat_info=os.stat(args.dir)
  gid=stat_info.st_gid
  group=grp.getgrgid(gid)[0]
else:
  group=args.group

#tell the user what we are going to do
print("Preparing to copy the following files to %s and change their group to '%s'"  % (args.dir, group))
for filename in args.files:
  if not re.search('^/', filename):
    filename=os.getcwd()+'/'+filename
  print("\t"+filename)

#ask for confirmation, make sure it is valid
answer=None
while answer is None:
  answer=raw_input("Proceed with copy (y/n)")
  if answer.lower() not in ['y', 'yes','n','no']:
    print("valid answers are y or n, please try again")
    answer=None

#do the work if answer was yes, if no, exit
if answer.lower() in ['y','yes']:
  print('copying files')
  for filename in args.files:
    if not re.search('^/', filename):
      filename=os.getcwd()+'/'+filename
    print("copy %s to %s" % (filename, args.dir+'/'+ntpath.basename(filename)))
    #copy file, report if error
    try:
      copyfile(filename,args.dir+'/'+ntpath.basename(filename))
    except:
      print("Error copyting file")
      quit()
    #print("chgrp %s on %s" % (group,args.dir+'/'+ntpath.basename(filename)))
    #get numeric group id to use, die if it does not exist
    try:
      gid = grp.getgrnam(group).gr_gid
    except:
      print("error determining proper group name")
      print("file copied, but permissions not set properly")
      quit()
    #change the file group, die if you cannot (like not having the right permissions)
    try:
      os.chown(args.dir+'/'+ntpath.basename(filename),-1,gid)
    except:
      print("unable to set group ownership to %s" % gid)
      print("file copied, but permissions not set properly")
      quit()
    #print("chmod 660 on %s" % args.dir+'/'+ntpath.basename(filename))
    #change the mode of the file to 660, again die if you cant do it
    try:
      os.chmod(args.dir+'/'+ntpath.basename(filename), 660)
    except:
      print("unable to set permissions own archive file %s" % args.dir+'/'+ntpath.basename(filename))
      print("file copied, but permissions not set properly")
      quit()
else:
  print('exiting program')
  quit()

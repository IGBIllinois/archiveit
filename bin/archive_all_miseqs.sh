#!/bin/bash

YEAR=2019
DAYS=180
LOCKFILE=/var/run/allmiseq

if [ -f $LOCKFILE ]; then
  echo $LOCKFILE already exists
else
  touch $LOCKFILE 
  miseq_archive.pl -dir=/storage3/MiSeq/MiSeq_1/ -dest=/archive/CBC/MiSeq/$YEAR/ -exclude miseq -user aghernan -group biotech-develope -days $DAYS
  miseq_archive.pl -dir=/storage3/MiSeq/MiSeq_2/ -dest=/archive/CBC/MiSeq/$YEAR/ -exclude miseq -user aghernan -group biotech-develope -days $DAYS
  miseq_archive.pl -dir=/storage3/MiSeq/MiSeq_3/ -dest=/archive/CBC/MiSeq/$YEAR/ -exclude miseq -user aghernan -group biotech-develope -days $DAYS
  rm $LOCKFILE
fi

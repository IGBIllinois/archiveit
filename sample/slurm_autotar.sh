#!/bin/bash
# ----------------SLURM Parameters----------------
#SBATCH -p normal
#SBATCH -n 4
#SBATCH --mem=4000m
#SBATCH -N 1
#SBATCH -J autotar
#SBATCH -D ~
# ----------------Load Modules--------------------
module load pbzip2
# ----------------Commands------------------------

SOURCEDIR=
DESTDIR=
GROUP=

#Calculate 90% of reserved memory.  Use this for maximum amount of memory for pbzip2
MEMORY=$(($SLURM_MEM_PER_NODE*90/100))


autotar --sourcedir $SOURCEDIR --destdir $DESTDIR --group $GROUP -p $SLURM_NTASKS -m $MEMORY

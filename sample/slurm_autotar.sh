#!/bin/bash
# ----------------SLURM Parameters----------------
#SBATCH -p normal
#SBATCH -n 1
#SBATCH --mem=4g
#SBATCH -N 1
#SBATCH -J autotar
#SBATCH -D ~
# ----------------Load Modules--------------------
module load pbzip2
# ----------------Commands------------------------
autotar --sourcedir --destdir --group 

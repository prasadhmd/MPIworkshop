#!/bin/bash
#SBATCH --job-name="workshop"
#SBATCH -n 4
#SBATCH -p backfill
#SBATCH -t 00:02:00

module load gnu-openmpi

srun -n 4 ./hello

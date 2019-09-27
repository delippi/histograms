#!/bin/ksh
#SBATCH -J bufr_hist@pdy@@cyc@_@window_size@
#SBATCH -t 0:30:00
#SBATCH -n 1
#SBATCH -q batch
#SBATCH -A fv3-cpu
#SBATCH -o bufrhist@pdy@@cyc@_@window_size@.out


./bufrhist.x < ./namelist

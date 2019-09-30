#!/bin/ksh

BASE=`pwd`
export ndate=/home/Donald.E.Lippi/bin/ndate

dir=/scratch2/NCEPDEV/fv3-cam/Donald.E.Lippi/hrlyGDAS/histograms/src/src_main/diags
bufrhit_x=$dir/*/*/*/bufrhist.x
bufrhist2019090500_short_out=$dir/*/*/*/bufrhist2019090500_short.out
namelist=$dir/*/*/*/namelist
setup_ksh=$dir/*/*/*/setup.ksh


echo "Be careful running this."
echo "Are you sure that you want to proceed the clean script? (y/n)"
read ans

if [[ $ans == 'y' ]]; then
   echo "Cleaning up executables"
   rm -f $bufrhit_x
   echo "Cleaning up extra files:"
   echo "1/2 namelists"
   rm -f $namelist
   echo "2/2 setup files"
   rm -f $setup_ksh
fi

#!/bin/ksh

#The user prescribes (num_days, start, and window_sizes). This script compiles the bufrhist.f90
#and kinds.f90 Fortran code. Then an end date is calculated from user input. A loop is run over
#each valid date with intervals of FH (usually 6 hours). Directories are created based on the
#valid time. Subdirectories are created for each window length. These directories are used as
#working directories. Template files (namelist and setup.ksh) are copied to these directories and
#modified inplace using the stream editor. The setup.ksh script is submitted as a batch job.

#module use -a /scratch2/NCEPDEV/nwprod/NCEPLIBS/modulefiles
export ndate=/home/Donald.E.Lippi/bin/ndate
BASE=`pwd`

host=`echo hostname | cut -c 1`
if [[ $host == 't' ]]; then
   machine="theia"
elif [[ $host == 'h' ]]; then
   machine="hera"
fi
ln -sf Makefile.$machine ./Makefile
make
#exit
err=$?
if [[ $err -ne 0 ]]; then
   echo "exit $err"
   exit "$err"
fi
exit
#/scratch2/BMC/gsienkf/whitaker/hrlygdas/rotdir/

#num_days=7.00 #user input (1 of 3) - does NOT include last time.
num_days=0.25 #user input (1 of 3) - does NOT include last time.
(( num_days_2hours=num_days*24 ))
start=2019070400 #user input (2 of 3)
#start=2019071100 #user input (2 of 3)
#start=2019071800 #user input (2 of 3)
#start=2019072500 #user input (2 of 3)
#start=2019080100 #user input (2 of 3)
#start=2019090100 #user input (2 of 3)
end=`${ndate} +$num_days_2hours ${start}`
window_sizes="short" #user input (3 of 3) - there isn't anything for "ops" or "long"

valtime=$start
FH=1 #6 - we want to do this hourly, not 6 hourly.
count=0
echo "You're about to run run.ksh to create the Fortran diag files of the hrylGDAS bufr dumps"
echo "num_days= "$num_days
echo "start   = "$start
echo "end     = "$end" (not including this time)"
echo "window_sizes= "$window_sizes
echo "Would you like to continue? (y/n)"
read ans
if [[ $ans != 'y' ]]; then
   exit
fi
while [[ $valtime -lt $end ]]; do
   cd $BASE
   echo "run.ksh: " $valtime
   mkdir -p $valtime
   PDY=`echo $valtime | cut -c 1-8`
   CYC=`echo $valtime | cut -c 9-10`

   for win in $window_sizes; do
       cd $BASE
       cd $valtime
       echo "run.ksh: " $win
       mkdir -p $win
       cd $win
       ln -sf $BASE/bufrhist.x .
       cp $BASE/namelist_template ./namelist
       sed -i "s/@window_size@/$win/g" namelist
       sed -i         "s/@pdy@/$PDY/g" namelist
       sed -i         "s/@cyc@/$CYC/g" namelist
       cp $BASE/setup_template.ksh ./setup.ksh 
       sed -i "s/@window_size@/$win/g" setup.ksh
       sed -i         "s/@pdy@/$PDY/g" setup.ksh 
       sed -i         "s/@cyc@/$CYC/g" setup.ksh
       sbatch ./setup.ksh
       #ksh ./setup.ksh
   done

   valtime=`${ndate} +$FH ${PDY}${CYC}`
   (( count+=1 ))
done
echo "run.ksh: " $count

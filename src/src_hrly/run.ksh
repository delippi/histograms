#!/bin/ksh

#The user prescribes (num_days, start, and window_sizes). This script compiles the bufrhist.f90
#and kinds.f90 Fortran code. Then an end date is calculated from user input. A loop is run over
#each valid date with intervals of FH (usually 6 hours). Directories are created based on the
#valid time. Subdirectories are created for each window length. These directories are used as
#working directories. Template files (namelist and setup.ksh) are copied to these directories and
#modified inplace using the stream editor. The setup.ksh script is submitted as a batch job.


export ndate=/home/Donald.E.Lippi/bin/ndate
BASE=`pwd`

make

err=$?
if [[ $err -ne 0 ]]; then
   echo "exit $err"
   exit "$err"
fi

num_days=0.25 #user input (1 of 3) - does NOT include last time.
(( num_days_2hours=num_days*24 ))
#start=2019070421 #user input (2 of 3)
start=2019070521 #user input (2 of 3)
#start=2019071800 #user input (2 of 3)
#start=2019072500 #user input (2 of 3)
#start=2019080100 #user input (2 of 3)
end=`${ndate} +$num_days_2hours ${start}`
#window_sizes="short long ops" #user input (3 of 3)
window_sizes="short long" #user input (3 of 3)

valtime=$start
FH=1
count=0
echo "You're about to run run.ksh to create the Fortran diag files of the hrylGDAS bufr dumps"
echo "num_days= "$num_days
echo "start   = "$start
echo "end     = "$end" (including this time)"
echo "window_sizes= "$window_sizes
echo "Would you like to continue? (y/n)"
read ans
if [[ $ans != 'y' ]]; then
   exit
fi
while [[ $valtime -le $end ]]; do
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

#!/bin/ksh

export ndate=/home/Donald.E.Lippi/bin/ndate
BASE=`pwd`
start=2019070400
end=2019071718
window_sizes="short long ops" #user input (3 of 3)
valtime=$start
FH=6
while [[ $valtime -le $end ]]; do
   cd $BASE
   echo "clean.ksh: " $valtime
   PDY=`echo $valtime | cut -c 1-8`
   CYC=`echo $valtime | cut -c 9-10`
   for win in $window_sizes; do
       cd $BASE
       rm -f $valtime/$win/namelist
       rm -f $valtime/$win/setup.ksh
       rm -f $valtime/$win/*out
       unlink $valtime/$win/bufrhist.x
   done
   valtime=`${ndate} +$FH ${PDY}${CYC}`
done


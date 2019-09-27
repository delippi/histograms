#!/bin/ksh

#The user prescribes (num_days and starts). Starts is a list of start times. For example,
#num_days=6.00 (0hr to 6hr - so really 7hrs) with starts="2019070500 2019070506 2019070512 2019070518"
#will create 4 figures each starting at their respected start time in starts. They will be a total
#aggregate count over the entire period at intervals specified by FH (usually 24). This means that
#for the start=2019070500 it will only include 00z counts from 2090705 through 20190711.

export ndate=/home/Donald.E.Lippi/bin/ndate

num_days=0.0 #can be a decimal value for partial days (e.g., 0.25=0hr + 6hr)
#num_days=0. #can be a decimal value for partial days (e.g., 0.25=0hr + 6hr)
(( num_days_2hours=num_days*24 ))
starts="2019070400 2019070406 2019070412 2019070418"
starts="2019070400 2019070406 2019070412 2019070418 2019070500 2019070506 2019070512 2019070518"
starts="2019070406"

#starts="2019071100 2019071106 2019071112 2019071118"
#starts="2019071800 2019071806 2019071812 2019071818"
#starts="2019072500 2019072506 2019072512 2019072518"
#starts="2019080100 2019080106 2019080112 2019080118"

starts="2019070400 2019070401 2019070402 2019070403 2019070404 2019070405"
#starts="2019070406 2019070407 2019070408 2019070409 2019070410 2019070411"
#starts="2019070412 2019070413 2019070414 2019070415 2019070416 2019070417"
#starts="2019070418 2019070419 2019070420 2019070421 2019070422 2019070423"

FH=1
ends=""
for start in $starts; do
    end=`${ndate} +$num_days_2hours ${start}`
    ends="$ends $end"
done

#Comprehensive list of bufr types (46 total).
bufr_types="1bamua 1bhrs4  1bmhs adpsfc adpupa aircar aircft airsev  amsr2 ascatt
            ascatw   atms atmsdb  atovs avcsam avcspm  bathy   cris crisdb esamua
            esatms escris eshrs3 esiasi  esmhs geoimr goesfv   gome gpsipw  gpsro
            iasidb mtiasi    omi osbuv8 proflr rassda saphir satwnd sevasr sevcsr
            sfcshp ssmisu status  tesac  trkob vadwnd prepbufr prepbufr.acft_profiles"
bufr_types="$bufr_types all total"

echo "You're about to run bufrhist.ksh to read the Fortran diag files of the hrylGDAS bufr dumps"
echo "num_days= "$num_days
echo "starts  = "$starts
echo "ends    = "$ends" (including this time)"
echo "bufr_types= "$bufr_types
echo "Would you like to continue? (y/n)"
read ans
if [[ $ans != 'y' ]]; then
   exit
fi


for start in $starts; do
    end=`${ndate} +$num_days_2hours ${start}`
    for bufr in $bufr_types; do
        if   [[ $bufr == "prepbufr" || $bufr == "prepbufr.acft_profiles" ]]; then
            mkdir -p ${start}_${end}/singles
            python bufrhist_prep.py $start $end $FH $bufr

        elif [[ $bufr == "all" ]]; then
            mkdir -p ${start}_${end}/all
            python bufrhist_all.py $start $end $FH "short"

        elif [[ $bufr == "total" ]]; then
            python bufrhist_total.py $start $end $FH

        else
            mkdir -p ${start}_${end}/singles
            python bufrhist_nonprep.py $start $end $FH $bufr
        fi
    done
done

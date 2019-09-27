program bufrhist

  use kinds,     only: r_kind,i_kind !r_double,i_kind,r_single
  implicit none

  !---------General declarations---------------!
  integer(i_kind) :: iret,idate,ireadmg,ireadsb,num_message,num_subset,tm,tmm,anl_time
  integer(i_kind),dimension(4) :: iadate
  integer(i_kind),dimension(2) :: iadate_prep
  integer(i_kind) :: unit_in=10
  integer(i_kind),dimension(13,4) :: bins1
  integer(i_kind),dimension(13,4) :: bins2
  integer(r_kind),dimension(13) :: tmxxa,tmxxb
  integer(i_kind) :: buf,stat
  character(8) :: pdy
  character(2) :: cyc
  character(5) :: window_size
  
  !---------BUFR VARS--------------------------!
  character(80)  :: path,path2 
  character(120)  :: bufrfilename
  character(80)   :: hdstr,hdstr_prep
  real(r_kind)    :: hdr(10)
  real(r_kind)    :: dhr,hour
!  character(8)    :: chdr
  character(8)    :: subset
  !character(8),dimension(47) :: bufr_types
  character(8),dimension(2) :: bufr_types

  !-------------TIMER VARS---------------------!
  integer(i_kind) :: time_array_0(8)
  integer(i_kind) :: time_array_1(8)
  integer(i_kind) :: hrs
  integer(i_kind) :: mins
  integer(i_kind) :: secs
  real(r_kind)    :: start_time
  real(r_kind)    :: finish_time
  real(r_kind)    :: total_time

  namelist/setup/window_size,pdy,cyc 

!--Call Timer
call date_and_time(values=time_array_0) !call timer
start_time = time_array_0(5)*3600 + time_array_0(6)*60 + time_array_0(7) + time_array_0(8)*0.001
write(6,*) 'BUFR INVENTORYING STARTED'

open(11,file='./namelist') !open namelist
read(11,setup)             !read namelist


hdstr="SAID CLAT CLON CLATH CLONH YEAR MNTH DAYS HOUR MINU" !header string of bufr file.
hdstr_prep="DHR" !OBSERVATION TIME MINUS CYCLE TIME
path="/scratch4/NCEPDEV/fv3-cam/noscrub/Donald.E.Lippi/hrlyGDAS/" !base path of bufr files.
path2="/scratch3/BMC/gsienkf/whitaker/hrlygdas/rotdir/"
bins1=0 !initialize all bins equal to zero
bins2=0 !initialize all bins equal to zero

!anl_time=00 !analysis time - need to NOT be hard coded.
read(cyc,*,iostat=stat) anl_time !convert cyc from namelist to integer variable.
tm=1
do while (tm <=13) !loop over 13 bins from -6 hour to +6 hours
   tmxxa(tm)=0-(7-tm) !compute the time minus values relative to the analysis time (e.g, -6,-5,...,+5,+6)
   tmxxb(tm)=24+anl_time-(7-tm) !compute the time minus values realtive to analysis time in UTC.
   if(tmxxb(tm) >=24) then; tmxxb(tm)=tmxxb(tm)-24; endif !correct values over 24
   if(tmxxb(tm) <  0) then; tmxxb(tm)=tmxxb(tm)+24; endif !correct values under 0
   write(6,*) tmxxa(tm),tmxxb(tm)
   tm=tm+1
enddo

!Comprehensive list of bufr types (46 total).
!bufr_types=(/"1bamua","1bhrs4", "1bmhs","adpsfc","adpupa","aircar","aircft","airsev", "amsr2","ascatt",&
!             "ascatw",  "atms","atmsdb", "atovs","avcsam","avcspm", "bathy",  "cris","crisdb","esamua",&
!             "esatms","escris","eshrs3","esiasi", "esmhs","geoimr","goesfv",  "gome","gpsipw", "gpsro",&
!             "iasidb","mtiasi",   "omi","osbuv8","proflr","rassda","saphir","satwnd","sevasr","sevcsr",&
!             "sfcshp","ssmisu","status", "tesac", "trkob","vadwnd","prepbufr"/)
bufr_types=(/"adpupa","gpsipw"/)
tm=0
do buf = 1,size(bufr_types) !loop over bufr types
   !variable bufr file name
   !'/scratch4/NCEPDEV/fv3-cam/noscrub/Donald.E.Lippi/hrlyGDAS/short/gdas.20190704/gdas.t00z.satwnd.tm00.bufr_d'
   if(trim(bufr_types(buf)) == "prepbufr") then
      bufrfilename=trim(path2)//'/gdas.'//pdy//'/'//cyc//'/gdas.t'//cyc//'z.'//trim(bufr_types(buf))
   else
      bufrfilename=trim(path)//trim(window_size)//'/gdas.'//pdy//'/gdas.t'//cyc//'z.'//trim(bufr_types(buf))//'.tm00.bufr_d'
      !bufrfilename=trim(path2)//'/gdas.'//pdy//'/'//cyc//'/gdas.t'//cyc//'z.'//trim(bufr_types(buf))//'.tm00.bufr_d.uniq'
   endif
   write(6,'(a120)') bufrfilename
   1000 format(a8,1x,a1,1x,i2,1x,a2,1x,i2)
   write(6,1000) trim(bufr_types(buf)),"-",buf,"of",size(bufr_types) !print progress
   open(unit=unit_in,file=trim(bufrfilename),status='old',action='read',form='unformatted')
   call openbf(unit_in,'IN',unit_in) !open bufr unit=unit_in as input with bufrtable unit=11
   call datelen(10)
   num_message=0
   msg_report: do while (ireadmg(unit_in,subset,idate) == 0 ) !read bufr messages
      num_message=num_message+1
      num_subset = 0 
      !write(*,'(I15,I8,a10)') idate,num_message,subset
      sb_report: do while (ireadsb(unit_in) == 0) !read bufr subset
        num_subset = num_subset+1

        if(trim(bufr_types(buf)) == "prepbufr") then
           call ufbint(unit_in,hdr,1,1 ,iret,hdstr_prep)
           dhr = hdr(1) !DHR
           dhr= anl_time+dhr
           if(dhr >=24) then; dhr=dhr-24; endif
           if(dhr <  0) then; dhr=dhr+24; endif
           
           iadate_prep(1)=int(dhr) !HOUR
           iadate_prep(2)=(dhr-iadate_prep(1))*60 !MINUTE
           tm=1
           do while(tm<=13)
              if(iadate_prep(1) == tmxxb(tm)) then
                 call sort_minute_left(iadate_prep(2),bins1(tm,:))
              endif
              tm=tm+1
           enddo
        else
           call ufbint(unit_in,hdr,10,1 ,iret,hdstr)
           iadate(1) = hdr(6)  !YEAR
           iadate(2) = hdr(7)  !MONTH
           iadate(3) = hdr(8)  !DAY
           iadate(4) = hdr(9)  !HOUR
           iadate(5) = hdr(10) !MINUTE
           if(iadate(5) < 0) then !adpupa doesn't have minutes, so this is necesary.
              iadate(5) = 0
           endif
           !write(6,*) iadate(1),iadate(2),iadate(3),iadate(4),iadate(5)
           !sort in place by hour,minute and ignore year,month,day
           tm=1
           do while (tm <=13)
              if(iadate(4) == tmxxb(tm)) then
                 call sort_minute_left(iadate(5),bins1(tm,:))
              end if
              tm=tm+1
           enddo
        endif

      enddo sb_report
   enddo msg_report

   tm=1
   !print cumulative data
   1003 format (a5,1x,a5,1x,a8,1x,a8,1x,a8,1x,a8)
   write(6,1003) "tmxxa","tmxxb","min00_14","min15_29","min30_44","min45_59" 
   do while (tm <=13)
      1004 format (i5,1x,i5,1x,i8,1x,i8,1x,i8,1x,i8)
      write(6,1004) tmxxa(tm),tmxxb(tm),bins1(tm,:)
      tm=tm+1
   enddo
   write(6,*) ""

   call closbf(unit_in)
   !write final counts to a new file for reading by python utility.
   open(unit=24,file="./"//trim(window_size)//"_"//pdy//cyc//"_inventory_"//trim(bufr_types(buf)),status='unknown')
   tm=1
   1001 format (a5,1x,a5,1x,a8,1x,a8,1x,a8,1x,a8)
   write(24,1001) "tmxxa","tmxxb","min00_14","min15_29","min30_44","min45_59" 
   write( 6,1001) "tmxxa","tmxxb","min00_14","min15_29","min30_44","min45_59" 
   do while (tm <=13)
      1002 format(i5,1x,i5,1x,i8,1x,i8,1x,i8,1x,i8)
      write(6, 1002) tmxxa(tm),tmxxb(tm),bins1(tm,1),bins1(tm,2),bins1(tm,3),bins1(tm,4)
      write(24,1002) tmxxa(tm),tmxxb(tm),bins1(tm,1),bins1(tm,2),bins1(tm,3),bins1(tm,4)
      tm=tm+1
   enddo
   close(24)
   bins2=bins2+bins1 !need the aggregate bins2
   bins1=0 !empty the bins
enddo

!write final counts to a new file for reading by python utility.
open(unit=24,file="./"//trim(window_size)//"_"//pdy//cyc//"_inventory",status='unknown')
tm=1
!1001 format (a5,1x,a5,1x,a8,1x,a8,1x,a8,1x,a8)
write(24,1001) "tmxxa","tmxxb","min00_14","min15_29","min30_44","min45_59" 
write( 6,1001) "tmxxa","tmxxb","min00_14","min15_29","min30_44","min45_59" 
do while (tm <=13)
   !1002 format(i5,1x,i5,1x,i8,1x,i8,1x,i8,1x,i8)
   write(6, 1002) tmxxa(tm),tmxxb(tm),bins2(tm,1),bins2(tm,2),bins2(tm,3),bins2(tm,4)
   write(24,1002) tmxxa(tm),tmxxb(tm),bins2(tm,1),bins2(tm,2),bins2(tm,3),bins2(tm,4)
   tm=tm+1
enddo
close(24)

!-Call Timer
call date_and_time(values=time_array_1)
finish_time = time_array_1(5)*3600 + time_array_1(6)*60 + time_array_1(7) + time_array_1(8)*0.001
total_time=finish_time-start_time
hrs =int(        total_time/3600.0       )
mins=int(    mod(total_time,3600.0)/60.0 )
secs=int(mod(mod(total_time,3600.0),60.0))
write(6,'(a14,i2.2,a1,i2.2,a1,i2.2)')"Elapsed time:   ",hrs,":",mins,":",secs
write(6,*) "Elapsed time (s) =", total_time
write(6,*) "end of program"



end program bufrhist


subroutine sort_minute_left(minu,bins_minu)
  !the subroutine sorts data into 15 minute left-oriented bins.
  use kinds, only: i_kind

  implicit none

  integer(i_kind),             intent(in   ) :: minu 
  integer(i_kind),dimension(4),intent(inout) :: bins_minu
  
     
     if(minu >= 0  .and. minu < 15) then
        bins_minu(1)=bins_minu(1)+1
     else if(minu >= 15 .and. minu < 30) then
        bins_minu(2)=bins_minu(2)+1
     else if(minu >= 30 .and. minu < 45) then
        bins_minu(3)=bins_minu(3)+1
     else if(minu >= 45 .and. minu < 60) then
        bins_minu(4)=bins_minu(4)+1
     end if

end subroutine sort_minute_left

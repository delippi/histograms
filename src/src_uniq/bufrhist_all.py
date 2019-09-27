from __future__ import print_function
import matplotlib
matplotlib.use("Agg")
import ncepbufr
import pandas as pd
from matplotlib import dates as mdates
import ncepy, sys
import numpy as np
import numpy.ma as ma
import matplotlib.pyplot as plt
import subprocess
from datetime import datetime
import matplotlib.colors as mcolors
from operator import add
import os
#pd.set_option('display.max_columns', None)  # or 1000
#pd.set_option('display.max_rows', None)  # or 1000
#pd.set_option('display.max_colwidth', -1)  # or 199
plt.style.use('ggplot')

import socket
hostname=socket.gethostname()
if(hostname[0] == "h"):
   BASE="/scratch2/NCEPDEV/fv3-cam/Donald.E.Lippi/hrlyGDAS/histograms/src/src_uniq"
if(hostname[0] == "t"):
   BASE="/scratch4/NCEPDEV/fv3-cam/noscrub/Donald.E.Lippi/hrlyGDAS/histograms/src/src_uniq/"
experiments=['short','long','ops']
experiments=['short']
colors=['r','b','k']
linestyles=['-','--','-.']
fig, axs = plt.subplots(1,1,sharey=True,sharex=True,figsize=(10,8),tight_layout=True)
fig_title_fontsize=14
sub_title_fontsize=11
xy_label_fontsize=11
tick_label_fontsize=8


start=str(sys.argv[1])
end=str(sys.argv[2])
fh=str(sys.argv[3])
win=str(sys.argv[4])
print("info: ",start,end,fh)

bin1=0
bin2=0
bin3=0
bin4=0

y_series=[[int(0)]*49]*47
time=0
colors=["maroon","brown","olive","teal","navy","black","red","orange","yellow","lime","green","cyan",\
        "blue","purple","magenta","grey","pink","apricot","beige","mint","lavender"]

colors=["black","gray","lightgray","rosybrown","brown","maroon","red","coral","sienna","chocolate",\
        "sandybrown","darkorange","darkgoldenrod","gold","olive","olivedrab","greenyellow","darkseagreen",\
        "forestgreen","limegreen","green","mediumaquamarine","turquoise","teal","cyan","cadetblue","lightblue",\
        "deepskyblue","steelblue","dodgerblue","royalblue","navy","blue","mediumpurple","blueviolet","indigo",\
        "darkviolet","violet","purple","magenta","orchid","mediumvioletred","deeppink","hotpink","crimson","pink"]

colors=["black","red","orange","gold","green","blue","indigo","violet"]*7
        


bufr_types=["1bamua","1bhrs4", "1bmhs","adpsfc","adpupa","aircar","aircft","airsev", "amsr2","ascatt",\
            "ascatw",  "atms","atmsdb", "atovs","avcsam","avcspm", "bathy",  "cris","crisdb","esamua",\
            "esatms","escris","eshrs3","esiasi", "esmhs","geoimr","goesfv",  "gome","gpsipw", "gpsro",\
            "iasidb","mtiasi",   "omi","osbuv8","proflr","rassda","saphir","satwnd","sevasr","sevcsr",\
            "sfcshp","ssmisu","status", "tesac", "trkob","vadwnd"]

x_series=np.arange(-6,6.25,0.25)
buf=0
for bufr_type in bufr_types:
  print("")
  print(win,bufr_type,"-all")
  valtime=start
  while valtime <= end:
   # y_series=[int(0)]*49
   #print(valtime,end)
   pdy=valtime[0:8]
   cyc=valtime[8:10]
   obs_inventory=BASE+"/"+valtime+"/"+win+"/"+win+"_"+valtime+"_inventory_"+bufr_type
   if(not os.path.isfile(obs_inventory)):
      print("file does not exist: "+obs_inventory)
      #update - end of while loop
      ndate="/home/Donald.E.Lippi/bin/ndate +"+fh+" "+valtime
      process = subprocess.Popen(ndate.split(),stdout=subprocess.PIPE)
      valtime,error = process.communicate()
      valtime=valtime.rstrip()
      continue

   df=pd.read_csv(obs_inventory,delimiter=r"\s+")
   df=df.stack()
   dummy_y=[]
   for i in range(13):
      dummy_y.append(df[i].min00_14)
      if( i != 12): #skip this for the 13th hour (+6) - we don't want 6:15+
         dummy_y.append(df[i].min15_29)
         dummy_y.append(df[i].min30_44)
         dummy_y.append(df[i].min45_59)

   time+=1
   dummy_y=np.array(dummy_y)
   y_series[buf]=np.array(y_series[buf])
   y_series[buf]=y_series[buf]+dummy_y
   #update - end of while loop
   ndate="/home/Donald.E.Lippi/bin/ndate +"+fh+" "+valtime
   process = subprocess.Popen(ndate.split(),stdout=subprocess.PIPE)
   valtime,error = process.communicate()
   valtime=valtime.rstrip()
  buf+=1
width=1
for i in range(buf): 
   if(i%8 == 0):
      width+=2.0
      j=0
   y_series[buf]=np.array(y_series[buf])
   y_sum=np.sum(y_series[i])
   plt.plot(x_series,y_series[i],color=colors[i],linewidth=width,label=bufr_types[i]+' ({})'.format(y_sum))
axs.legend(ncol=2)
plt.xticks(x_series)
for tick in axs.get_xticklabels(): #format x labels
    tick.set_rotation(90)
    plt.setp(tick,visible=True,fontsize=tick_label_fontsize)
for tick in axs.get_yticklabels(): #format y labels
    plt.setp(tick,visible=True,fontsize=tick_label_fontsize)
plt.axvline(0, color='black',linewidth=1)

#for i,j in zip(x_series,y_series):
#    if(j<1000000): axs.annotate(str(j),xy=(i,j),color=colors[0],rotation='vertical',verticalalignment='top',\
#                           horizontalalignment='right')



title="hourly GDAS bufr data counts\n"\
     +"%s: %s to %s (%sz cycles)" % (str(bufr_type),str(start),str(end),str(cyc).zfill(2))
plt.title(title,fontsize=fig_title_fontsize)
plt.xlabel("Time",fontsize=xy_label_fontsize)
plt.ylabel("Number of Obs",fontsize=xy_label_fontsize)
plt.show()
plt.savefig("./%s_%s/all/inventory_all_%s_to_%s_%sz.png" % \
           (str(start),str(end),str(start),str(end),str(cyc).zfill(2)))

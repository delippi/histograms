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

BASE="/scratch2/NCEPDEV/fv3-cam/Donald.E.Lippi/hrlyGDAS/histograms/src/src_main/"
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
bufr_type=str(sys.argv[4])
print("info: ",start,end,fh)

bin1=0
bin2=0
bin3=0
bin4=0

y_series_short=[int(0)]*49
time=0
count=0
windows=["short"]
for win in windows:
 print("")
 print(win,bufr_type)
 valtime=start
 while valtime <= end:
   #print(valtime,end)
   pdy=valtime[0:8]
   cyc=valtime[8:10]
   #print(pdy,cyc)
   obs_inventory=BASE+"/diags/"+pdy+"/"+cyc+"/"+win+"/"+win+"_"+valtime+"_inventory_"+bufr_type
   if(os.path.isfile(obs_inventory)):
      count+=1
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
   if(win == "short"):
      y_series_short=np.array(y_series_short)
      y_series_short=y_series_short+dummy_y
      y_sum_short=np.sum(y_series_short)

   #update - end of while loop
   ndate="/home/Donald.E.Lippi/bin/ndate +"+fh+" "+valtime
   process = subprocess.Popen(ndate.split(),stdout=subprocess.PIPE)
   valtime,error = process.communicate()
   valtime=valtime.rstrip()

if(count>0):
   x_series=np.arange(-6,6.25,0.25)
   plt.plot(x_series,y_series_short,color=colors[0],linewidth=3,linestyle=linestyles[0],label='short ({})'.format(y_sum_short))
   axs.legend()
   plt.xticks(x_series)


   for tick in axs.get_xticklabels(): #format x labels
       tick.set_rotation(90)
       plt.setp(tick,visible=True,fontsize=tick_label_fontsize)
   for tick in axs.get_yticklabels(): #format y labels
       plt.setp(tick,visible=True,fontsize=tick_label_fontsize)
   plt.axvline(0, color='black',linewidth=1)

   for i,j in zip(x_series,y_series_short):
       if(j<1000000): axs.annotate(str(j),xy=(i,j),color=colors[0],rotation='vertical',verticalalignment='top',\
                           horizontalalignment='right')

   title="hourly GDAS bufr data counts\n"\
        +"%s: %s to %s (%sz cycles)" % (str(bufr_type),str(start),str(end),str(cyc).zfill(2))
   plt.title(title,fontsize=fig_title_fontsize)
   plt.xlabel("Time",fontsize=xy_label_fontsize)
   plt.ylabel("Number of Obs",fontsize=xy_label_fontsize)
   plt.show()
   plt.savefig("./%s_%s/singles/inventory_%s_%s_to_%s_%sz.png" % \
              (str(start),str(end),str(bufr_type),str(start),str(end),str(cyc).zfill(2)))

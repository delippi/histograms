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
#pd.set_option('display.max_columns', None)  # or 1000
#pd.set_option('display.max_rows', None)  # or 1000
#pd.set_option('display.max_colwidth', -1)  # or 199
plt.style.use('ggplot')

BASE="/scratch4/NCEPDEV/fv3-cam/noscrub/Donald.E.Lippi/hrlyGDAS/histograms/src/src_hrly/"
#experiments=['short','long','ops']
experiments=['short','long']
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
print("info: ",start,end,fh)

bin1=0
bin2=0
bin3=0
bin4=0

y_series_short=[int(0)]*49
y_series_long=[int(0)]*49
y_series_ops=[int(0)]*49
time=0
#windows=["short","long","ops"]
windows=["short","long"]
for win in windows:
 print("")
 print(win)
 valtime=start
 while valtime <= end:
   print(valtime,end)
   pdy=valtime[0:8]
   cyc=valtime[8:10]
   #print(pdy,cyc)
   obs_inventory=BASE+"/"+valtime+"/"+win+"/"+win+"_"+valtime+"_inventory"

   df=pd.read_csv(obs_inventory,delimiter=r"\s+")
   print(df)
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
   if(win == "long"):
      y_series_long=np.array(y_series_long)
      y_series_long=y_series_long+dummy_y
   if(win == "ops"):
      y_series_ops=np.array(y_series_ops)
      y_series_ops=y_series_ops+dummy_y


   #update - end of while loop
   ndate="/home/Donald.E.Lippi/bin/ndate +"+fh+" "+valtime
   process = subprocess.Popen(ndate.split(),stdout=subprocess.PIPE)
   valtime,error = process.communicate()
   valtime=valtime.rstrip()

x_series=np.arange(-6,6.25,0.25)
#print(len(x_series))
#print(len(y_series_short))
plt.plot(x_series,y_series_short,color=colors[0],linewidth=3,linestyle=linestyles[0],label='short')
plt.plot(x_series,y_series_long,color=colors[1],linewidth=3,linestyle=linestyles[1],label='long')
#plt.plot(x_series,y_series_ops,color=colors[2],linewidth=3,linestyle=linestyles[2],label='ops')
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
for i,j in zip(x_series,y_series_long):
    if(j<1000000): axs.annotate(str(j),xy=(i,j),color=colors[1],rotation='vertical',verticalalignment='center',\
                           horizontalalignment='center')
#for i,j in zip(x_series,y_series_ops):
#    if(j<1000000): axs.annotate(str(j),xy=(i,j),color=colors[2],rotation='vertical',verticalalignment='bottom',\
#                           horizontalalignment='left')

#plt.yscale("log")


title="hourly GDAS (short and long) and operational GDAS data counts\n"\
     +"%s to %s (%sz cycles)" % (str(start),str(end),str(cyc).zfill(2))
plt.title(title,fontsize=fig_title_fontsize)
plt.xlabel("Time",fontsize=xy_label_fontsize)
plt.ylabel("Number of Obs",fontsize=xy_label_fontsize)
plt.show()
plt.savefig("./%s_%s/inventory_%s_to_%s_%sz.png" % \
           (str(start),str(end),str(start),str(end),str(cyc).zfill(2)))

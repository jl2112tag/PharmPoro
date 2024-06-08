from scancontrolclient import ScanControlClient
import time
import base64
import csv
import numpy as np
import argparse
# from datetime import datetime

# address="10.0.2.74"       # set IP address of system to use
address="localhost"         # use this instead of IP address if running code directly on machine
waveform_average = 1

# create the argument parser
parser = argparse.ArgumentParser(description = 'average, mode, number(time or count)')

# add arguments
parser.add_argument('--average', type = int, help = 'waveform_average')
args = parser.parse_args()

# Scan options
if args.average is not None:
    waveform_average = args.average

print('waveform_average =',str(int(waveform_average)))
    
vecData = []
avgReset = False
FileName = 'tabletRead.csv'
i=1

#%%
def getPulse(data):
    global i, waveform_average, start_time, avgReset, current_rate, vecData
    ScanControl.setDesiredAverages(waveform_average)
    numAvg = ScanControl.currentAverages
    current_rate = ScanControl.rate
    
    if numAvg < waveform_average or 1 == waveform_average:
        avgReset = True
    
    if numAvg == waveform_average and avgReset:
        avgReset = False
        
        timeAxis=np.asarray(np.frombuffer(base64.b64decode(ScanControl.timeAxis), dtype=np.float64)) # import time axis (x-axis)
        timeAxis = np.insert(timeAxis,0,0)
        vecData = timeAxis
        with open(FileName,'w', newline='') as f_meas:
            writer = csv.writer(f_meas)
            writer.writerow(vecData)
                    
        ms = round(time.time()*1000)/1000 # measurement time in milliseconds
        eAmp = data['amplitude'][0] # import E-field data
        eAmp = np.insert(eAmp,0,ms)
        vecData = eAmp
        with open(FileName,'a', newline='') as f_meas:
            writer = csv.writer(f_meas)
            writer.writerow(vecData)
    
        # ScanControl.resetAveraging()
        print(str(i)+' measured.')
        with open('progress.txt','w') as f_prog:
            progress_message = f"{i} measured"
            f_prog.write(progress_message)
            f_prog.flush()
        i = i+1

    if i > 1:
        ScanControl.stop()
        client.loop.stop()   
        print(f"Measurement done!")                         
        with open('progress.txt','w') as f:
            progress_message = f"Measurement done!"
            f.write(progress_message)
            f.flush()

#%%

client = ScanControlClient()
client.connect(host=address)
ScanControl = client.scancontrol
ScanControl.resetAveraging()
client.loop.run_until_complete(ScanControl.start())
ScanControl.pulseReady.connect(getPulse)
client.loop.run_forever()
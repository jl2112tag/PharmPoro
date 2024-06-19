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
statusFile = 'progress.txt'
measurementFile = 'tabletRead.csv'
getData = True;

#%%
def getPulse(data):
    global waveform_average, start_time, avgReset, vecData, getData
    ScanControl.setDesiredAverages(waveform_average)
    numAvg = ScanControl.currentAverages
    
    if numAvg < waveform_average or 1 == waveform_average:
        avgReset = True
    
    if numAvg == waveform_average and avgReset:
        avgReset = False
        
        if getData:
            timeAxis=np.asarray(np.frombuffer(base64.b64decode(ScanControl.timeAxis), dtype=np.float64)) # import time axis (x-axis)
            timeAxis = np.insert(timeAxis,0,0)
            vecData = timeAxis
            with open(measurementFile,'w', newline='') as f_meas:
                writer = csv.writer(f_meas)
                writer.writerow(vecData)

            ms = round(time.time()*1000)/1000 # measurement time in milliseconds
            eAmp = data['amplitude'][0] # import E-field data
            eAmp = np.insert(eAmp,0,ms)
            vecData = eAmp
            with open(measurementFile,'a', newline='') as f_meas:
                writer = csv.writer(f_meas)
                writer.writerow(vecData)
    
            write_status("1 measured")
            waveform_average = 1
            getData = False
        else:
            ScanControl.stop()
            client.loop.stop()   
            print(f"{numAvg} waveform average")                        
            write_status(f"Measurement done!")

def write_status(msg):
    print(msg)
    with open(statusFile,'w') as f:
        f.write(msg)
        f.flush()

client = ScanControlClient()
client.connect(host=address)
ScanControl = client.scancontrol
write_status("Python script runs")
ScanControl.resetAveraging()
client.loop.run_until_complete(ScanControl.start())
ScanControl.pulseReady.connect(getPulse)
client.loop.run_forever()
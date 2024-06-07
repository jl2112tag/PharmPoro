# PharmPoro (Terahertz Pharmaceutical Tablet Porosity Measurment Software)
- See below UI image
- Note: only compatible with MenloSystems TeraSmart (ScanControl application via Python websocket)

<img src="UI_image.png" height ="500">

** Installation Guide**
A: Python environment settting
 1. Install Python 3.9.13 (May 17 2022) - compatible with MATLAB version > R2021b
 - Install
 - Customize installation
 - Install laucher for all users check!
 - Add Python 3.9 to PATH
 - Options all check!
 - Customize install location: Browse -> C:\Python\Python39
 - Install -> complete

2. Spyder IDE installation (or anyother Python IDEs can be installed)
 - Lauch Spyder -> menu -> Tools -> Preferences -> Python Interpreter -> Default to C:\Python\Python39\Python.exe -> Apply -> OK
 - (Windows command prompt) > pip install spyder-kernels==2.5.* (enter)

3. Package installation
 (Windows command prompt) <- Windows search "cmd" (enter)
 - pip install PyQt5 (enter)
 - pip install websockets (enter)
 - pip install numpy (enter)
 - pip install astropy (enter)

B: Windows setting 
 4. Windows path setting
 - Windows taskbar -> Search with 'environment variables' -> Edit the system environment variables
 -> Advanced tab -> Environment Variables button -> New
 -> Name: PYTHONPATH, Value: -> Browse directory: C:\Python\Python39\Lib\Site-packages (site-package directory)
 -> OK -> OK

C: PharmPoro Installation
 5. Copy all python scripts to \PharmPoro directory
 - _pycache_ folder
 - pywebchannel
 - readReflections.py
 - scancontrolclient.py

 6. Lauch PharmPoro.exe

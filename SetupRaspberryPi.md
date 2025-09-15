Tutorial for setup Rasp Pi 4+5

You need:
- Raspberry Pi 4 or 5
- SD Card
- Raspberry Pi Imager
1.
Start the Imager:

![Rasp_imager1](images/Rasp_imager1.jpg)  

Select Pi version, os (Raspberry Pi OS Lite 64bit), Your SD card 

2. Change Setup Settings
   
![Rasp_imager2](images/Rasp_imager2.jpg)

Setup with your Data Hostname,User,Wifi data

![Rasp_imager3](images/Rasp_imager3.jpg)

3. Switch to the services tab

   - please check SSH is active

  ![Rasp_imager4](images/Rasp_imager4.jpg)

  Save and write the Image to the SD. 
  SD is Ready for the Pi

  
  4. Insert the SD card back to the Pi and power on.
     - wait 5 min or better get a coffee


 Start a SSH tool on your PC and Login to your Pi with your Data 
  
==============================================================================================================
2A >>>>>Raspberry Pi 4 <<<<

2.1Change the Config.txt: 

```
sudo su
```
```
nano /boot/firmware/config.txt 
```
Change to this parameters or overwrite all
```
# For more options and information see
# http://rptl.io/configtxt
# Some settings may impact device functionality. See link above for details

# Uncomment some or all of these to enable the optional hardware interfaces
#dtparam=i2c_arm=on
#dtparam=i2s=on
dtparam=spi=on

# Enable audio (loads snd_bcm2835)
dtparam=audio=on

# Additional overlays and parameters are documented
# /boot/firmware/overlays/README

# Automatically load overlays for detected cameras
camera_auto_detect=1

# Automatically load overlays for detected DSI displays
display_auto_detect=1

# Automatically load initramfs files, if found
auto_initramfs=1

# Enable DRM VC4 V3D driver
dtoverlay=vc4-kms-v3d
max_framebuffers=2

# Don't have the firmware create an initial video= setting in cmdline.txt.
# Use the kernel's default instead.
disable_fw_kms_setup=1

# Run in 64-bit mode
arm_64bit=1

# Disable compensation for displays with overscan
disable_overscan=1

# Run as fast as firmware / board allows
arm_boost=1

[cm4]
# Enable host mode on the 2711 built-in XHCI USB controller.
# This line should be removed if the legacy DWC2 controller is required
# (e.g. for USB device mode) or if USB support is not required.

# Disabled for klipper S1
#otg_mode=1

[cm5]
#dtoverlay=dwc2,dr_mode=host

[all]
dtoverlay=dwc2
modules-load=dwc2

#hdmi_force_hotplug=0
enable_uart=1
```
Save with CTRL+O Enter and exit with CTRL+X Enter

2.2 Change cmdline.txt

```nano /boot/firmware/cmdline.txt```


please add this after rootwait so that it looks like below

```modules-load=dwc2,libcomposite```

"rootwait modules-load=dwc2,libcomposite cfg80211.ieee80211_regdom=DE"

Save CTRL+O and Exit CTRL+X

2.3 Create the Ports.sh :

```echo > /opt/ports.sh```

```nano /opt/ports.sh```

Please Copy this to the Nano Window
```
#!/bin/bash
modprobe libcomposite
cd /sys/kernel/config/usb_gadget/
mkdir -p klipper
cd klipper

echo 0x1d6b > idVendor
echo 0x0104 > idProduct
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB

mkdir -p strings/0x409
echo "1234567890" > strings/0x409/serialnumber
echo "KlipperPi" > strings/0x409/manufacturer
echo "VirtualSerialBridge" > strings/0x409/product

mkdir -p configs/c.1/strings/0x409
echo "Config 1" > configs/c.1/strings/0x409/configuration

# First serial interface
mkdir functions/acm.usb0
ln -s functions/acm.usb0 configs/c.1/

# Second serial interface
mkdir functions/acm.usb1
ln -s functions/acm.usb1 configs/c.1/
# Bind to UDC
echo $(ls /sys/class/udc) > UDC
```
Save CTRL+O Enter and  Exit CTRL+X Enter

Ports.sh give user Rights

```chmod +x /opt/ports.sh```

2.3 Create the service in systemd:

```echo > /etc/systemd/system/ports.service```

 EDIT File
```nano /etc/systemd/system/ports.service```

Copy this into the file
```
[Unit]
Description=USB Serial Bridge Script
After=network.target syslog.target

[Service]
Type=simple
ExecStart=/opt/ports.sh
User=root
WorkingDirectory=/opt
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
Save and Exit CTRL+O,CTRL+X


2.4
Activate the Service:

```
systemctl daemon-reload
systemctl start ports.service
systemctl enable ports.service
```
you can check the service is running
```systemctl status ports.service```

You can see this then all ok (my servie is named virtual_usb its the same)
![Term1](images/Term1.jpg)

Raspberry is ready for Klipper >> [Klipper install](klipperinstall.md) 
==============================================================================================================
2.B >>>> Raspberry 5 <<<<< 

2.1 Change the Config.txt: 

```
sudo su
```
```
nano /boot/firmware/config.txt 
```
Change to this parameters or overwrite all
```
# For more options and information see
# http://rptl.io/configtxt
# Some settings may impact device functionality. See link above for details

# Uncomment some or all of these to enable the optional hardware interfaces
#dtparam=i2c_arm=on
#dtparam=i2s=on
#dtparam=spi=on

# Enable audio (loads snd_bcm2835)
dtparam=audio=on

# Additional overlays and parameters are documented
# /boot/firmware/overlays/README

# Automatically load overlays for detected cameras
camera_auto_detect=1

# Automatically load overlays for detected DSI displays
display_auto_detect=1

# Automatically load initramfs files, if found
auto_initramfs=1

# Enable DRM VC4 V3D driver
dtoverlay=vc4-kms-v3d
max_framebuffers=2

# Don't have the firmware create an initial video= setting in cmdline.txt.
# Use the kernel's default instead.
disable_fw_kms_setup=1

# Run in 64-bit mode
arm_64bit=1

# Disable compensation for displays with overscan
disable_overscan=1

# Run as fast as firmware / board allows
arm_boost=1

[cm4]
# Enable host mode on the 2711 built-in XHCI USB controller.
# This line should be removed if the legacy DWC2 controller is required
# (e.g. for USB device mode) or if USB support is not required.
otg_mode=1

[cm5]
dtoverlay=dwc2,dr_mode=host

[all]

[pi5]
dtoverlay=dwc2
```
Save with CTRL+O Enter and exit with CTRL+X Enter

2.2 Create the Modules
```echo > /etc/modules```

Edit the modules file:
```nano /etc/modules```

please add this:
```dwc2
   libcomposite
```
Save and Exit CTRL+O,CTRL+X

2.3 Create the Ports.sh :

```echo > /opt/ports.sh```

```nano /opt/ports.sh```

Please Copy this to the Nano Window
```
#!/bin/bash
modprobe libcomposite
cd /sys/kernel/config/usb_gadget/
mkdir -p klipper
cd klipper

echo 0x1d6b > idVendor
echo 0x0104 > idProduct
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB

mkdir -p strings/0x409
echo "1234567890" > strings/0x409/serialnumber
echo "KlipperPi" > strings/0x409/manufacturer
echo "VirtualSerialBridge" > strings/0x409/product

mkdir -p configs/c.1/strings/0x409
echo "Config 1" > configs/c.1/strings/0x409/configuration

# First serial interface
mkdir functions/acm.usb0
ln -s functions/acm.usb0 configs/c.1/

# Second serial interface
mkdir functions/acm.usb1
ln -s functions/acm.usb1 configs/c.1/
# Bind to UDC
echo $(ls /sys/class/udc) > UDC
```
Save CTRL+O Enter and  Exit CTRL+X Enter

Ports.sh give user Rights

```chmod +x /opt/ports.sh```

2.3 Create the service in systemd:

```echo > /etc/systemd/system/ports.service```

 EDIT File
```nano /etc/systemd/system/ports.service```

Copy this into the file
```
[Unit]
Description=USB Serial Bridge Script
After=network.target syslog.target

[Service]
Type=simple
ExecStart=/opt/ports.sh
User=root
WorkingDirectory=/opt
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
Save and Exit CTRL+O,CTRL+X


2.4
Activate the Service:

```
systemctl daemon-reload
systemctl enable ports.service
systemctl start ports.service
```
you can check the service is running
```systemctl status ports.service```

You can see this then all ok (my servie is named virtual_usb its the same)
![Term1](images/Term1.jpg)

Raspberry is ready for Klipper >> [Klipper install](klipperinstall.md) 

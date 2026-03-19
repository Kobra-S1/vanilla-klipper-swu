# KlipperScreen Viewer

Standalone Rinkhals app that displays a remote KlipperScreen VNC session on the
printer touchscreen and forwards touch input back to the VNC server.

This app ships its own `fb-vnc-viewer` binary and can be installed on an
existing Rinkhals system.

WARNING: Only KS1 was tested, support for other printers is not tested at all and will propably not work yet.

Package mapping:
- `update-k2p-k3.swu`: K2P, K3, K3V2
- `update-ks1.swu`: KS1, KS1M
- `update-k3m.swu`: K3M

## App configuration
Edit this textfile on the printer `/useremain/rinkhals/klipperscreen-viewer.conf`to configure the app.
At least the IP to the vnc-server needs to be provided there:

```bash
VNC_HOST=<rpi-ip>
```
## Raspberry Pi setup
Install procedure to install the needed vnc-server, klipper-screen-vnc service with KS1 profile.
Assumption is, you already have klipper-screen installed ony our RPI (if not, use kiauh to do that before).

(If your are using also my ACEPRO klipper-screen, also update that one (acepro.py) as it got recent update to fit more nicely on the KS1 display).

Download the script into your RPI, make it executable and run setup with KS1 profile:
```
wget -O rpi-setup.sh https://raw.githubusercontent.com/Kobra-S1/vanilla-klipper-swu/main/klipperscreen-viewer-app/rpi-setup.sh

chmod +x rpi-setup.sh
sudo ./rpi-setup.sh --profile ks1
```
After that, the RPI has installed the necessary vnc-server and starts a dedicated klipper-screen systemd service.
Keep that in mind if you change anything in klipper screen itself, for change taking effect you also need to restart this additional service.

## Install

Install the SWU from USB as `update.swu` to your printer, 

IMPORTANT: Update in the configuration file afterwards the IP of your RPI,so the viewer know where to connect to.

```
/useremain/rinkhals/klipperscreen-viewer.conf
```

Then start/enable the app from the Rinkhals App UI or run:

```
/useremain/home/rinkhals/apps/klipperscreen-viewer/app.sh start
```

To stop the app and get K3SysUI back, either call the above script with "stop" via ssh, or touch and hold for >5 seconds the top left corner of the klipperscreen.

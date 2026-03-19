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

## Printer-side model mapping

The app automatically selects viewer rotation from `KOBRA_MODEL_CODE`:

| Model | Expected VNC size | Rotation |
|---|---:|---:|
| KS1 | 800x480 | 180 |
| KS1M | 800x480 | 180 |
| K3M | 480x272 | 90 |
| K2P | 480x272 | 270 |
| K3 | 480x272 | 270 |
| K3V2 | 480x272 | 270 |

Optional override in `/useremain/rinkhals/klipperscreen-viewer.conf`:

```bash
VNC_HOST=<rpi-ip>
```
## Raspberry Pi setup
Install cheat-sheet for KS1 profile.

Download the script into your RPI, make it executable and run setup with KS1 profile:
```
wget -O rpi-setup.sh https://raw.githubusercontent.com/Kobra-S1/vanilla-klipper-swu/main/klipperscreen-viewer-app/rpi-setup.sh

chmod +x rpi-setup.sh
sudo ./rpi-setup.sh --profile ks1
```

## Install

Install the SWU from USB as `update.swu` to your printer, 

IMPORTANT: Update in the configuration file the IP of your RPI,so the viewer know where to connect to.

```
/useremain/rinkhals/klipperscreen-viewer.conf
```

Then start/enable the app from the Rinkhals App UI or run:

```
/useremain/home/rinkhals/apps/klipperscreen-viewer/app.sh start
```

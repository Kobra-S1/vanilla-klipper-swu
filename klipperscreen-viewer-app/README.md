# KlipperScreen Viewer

Standalone Rinkhals app that displays a remote KlipperScreen VNC session on the
printer touchscreen and forwards touch input back to the VNC server.

This app ships its own `fb-vnc-viewer` binary and can be installed on an
existing Rinkhals system.

WARNING: Only KS1 and K3 was tested properly. Support for other printers (KS1M, K2P,K3m) may not work correctly yet. I dont have those printers, so cant test.

Package mapping:
- `update-k2p-k3.swu`: K2P, K3, K3V2
- `update-ks1.swu`: KS1, KS1M
- `update-k3m.swu`: K3M

## App Configuration

Edit this file on the printer:

```bash
/useremain/rinkhals/klipperscreen-viewer.conf
```

At minimum, set the VNC server IP or hostname:

```bash
VNC_HOST=<rpi-ip-or-hostname>
```

Most installations should leave the model-specific settings empty. The app
auto-detects the printer model and applies the correct defaults for rotation
and touch handling. Only override those values if you know you need to.

## Raspberry Pi Setup

This assumes KlipperScreen is already installed on the Raspberry Pi. If not,
install it first, for example with KIAUH.

If you also use the ACE Pro KlipperScreen integration, update that too before
testing this viewer so the layout matches the printer screen better.

Download the setup script to the Raspberry Pi, make it executable, and run it
with the matching printer profile. Example for KS1:

```bash
wget -O rpi-setup.sh https://raw.githubusercontent.com/Kobra-S1/vanilla-klipper-swu/main/klipperscreen-viewer-app/rpi-setup.sh
chmod +x rpi-setup.sh
sudo ./rpi-setup.sh --profile ks1
```

Example profiles:
- `ks1`
- `ks1m`
- `k3`
- `k3v2`
- `k2p`
- `k3m`

This installs the required VNC server and creates a dedicated
`klipperscreen-vnc` systemd service on the Pi.

If you later change KlipperScreen itself, restart that Pi-side service so the
changes take effect.

## Install On Printer

Install the correct SWU from USB as `update.swu` on the printer.

After installation, update the app config on the printer so the viewer knows
where to connect:

```bash
/useremain/rinkhals/klipperscreen-viewer.conf
```

At minimum:

```bash
VNC_HOST=<rpi-ip-or-hostname>
```

Then start or enable the app from the Rinkhals Apps UI, or run:

```bash
/useremain/home/rinkhals/apps/klipperscreen-viewer/app.sh start
```

## Stop

To stop the app and return to the normal printer UI:

- run `/useremain/home/rinkhals/apps/klipperscreen-viewer/app.sh stop` over SSH
- or touch and hold the top-left corner of the KlipperScreen view for more than 5 seconds

> **Notice:** Closing the app (e.g. via long press) has side effects on the built-in printer UI. Because `K3SysUI` has to be killed and restarted in the background, it will likely experience glitches and not function correctly afterwards. Closing the viewer app is primarily intended as an emergency escape to reach the Rinkhals UI so you can stop or disable the app if needed. A full restart of the printer is highly recommended after closing it. This app is targeted to use the display fully as a continuous KlipperScreen viewer.

## Full Uninstall

### On the printer

Stop the app first:

```bash
/useremain/home/rinkhals/apps/klipperscreen-viewer/app.sh stop
```

Then remove the app and its config:

```bash
rm -rf /useremain/home/rinkhals/apps/klipperscreen-viewer
rm -f /useremain/rinkhals/klipperscreen-viewer.conf
```

If you installed it through the Rinkhals Apps UI, you can also disable or remove
it there first, then delete the config file above if you want to remove all
saved settings.

### On the Raspberry Pi

Stop and remove the Pi-side service and wrapper created by `rpi-setup.sh`:

```bash
sudo systemctl disable --now klipperscreen-vnc.service
sudo rm -f /etc/systemd/system/klipperscreen-vnc.service
sudo rm -f /usr/local/bin/klipperscreen-vnc.sh
sudo systemctl daemon-reload
```

If this Pi only used TigerVNC for this viewer, you can also remove that package:

```bash
sudo apt-get remove -y tigervnc-standalone-server
```

`rpi-setup.sh` may also have added `screen_blanking = off` to your
KlipperScreen config. Check one of these files, depending on your setup:

```bash
/home/pi/printer_data/config/KlipperScreen.conf
/home/pi/klipper_config/KlipperScreen.conf
```

If you want to fully undo the setup, remove that line again. If the script
created the whole file just for this setting and you do not need any other
KlipperScreen customizations, you can delete the file instead.

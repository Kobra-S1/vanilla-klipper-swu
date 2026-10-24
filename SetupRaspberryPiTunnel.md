# 🥧 Raspberry Pi / Raspberry Pi Zero 2 W / BTT Pi2 — Setup Tunnel Tutorial

[← Repository overview](README.md)

**Tunneled-Klipper setup:** [1. Overview](tunneled-klipper.md) → **2. SBC setup** → [3. Klipper on SBC](klipper_install.md) → [4. Printer display](klipperscreen-viewer-app/README.md) *(optional)*

This tutorial explains how to set up a Raspberry Pi 4/5, Compute Module 4/5, Zero 2 W, or BTT Pi2 (BigTreeTech CB2) and prepare it as a USB Serial Bridge (e.g., for Klipper).

---

## 📦 Requirements

* Raspberry Pi 4, 5, Compute Module 4/5, or Zero 2 W (Raspberry Pi OS Lite 64-bit), or BTT Pi2 (Armbian)
* SD card
* Raspberry Pi Imager (for Raspberry Pi boards) or Armbian image tool of your choice (for BTT Pi2)

> ⚠️ **Raspberry Pi Zero 2 W note:** Zero 2 W is listed only because it supports OTG serial gadget mode. It is **not recommended** for Klipper workloads due to limited CPU and RAM.
>
> If you still use Zero 2 W, avoid running camera streaming (for example crowsnest) on the same device to reduce load and help prevent MCU communication errors during prints.

---

## 🖼 Step 1 – Write Image

Open the **Raspberry Pi Imager**:

![Rasp\_imager1](images/Rasp_imager1.jpg)

Select your **Pi model**, the **operating system (Raspberry Pi OS Lite 64-bit)**, and your **SD card**.

For **BTT Pi2**, flash a current **Armbian Bookworm** image and boot it once.

Official BTT CB2 image releases:
- https://github.com/bigtreetech/CB2/releases

---

## 🧰 Step 2 – Configure Setup

![Rasp\_imager2](images/Rasp_imager2.jpg)

Enter your **hostname**, **username**, **password**, and **Wi-Fi credentials**:

![Rasp\_imager3](images/Rasp_imager3.jpg)

---

## 🔐 Step 3 – Enable SSH

Go to the **Services** tab and enable **SSH**:

![Rasp\_imager4](images/Rasp_imager4.jpg)

Save the settings and write the image to the SD card. Your **SD card is now ready for the Pi**.

---

## ⚡ Step 4 – Boot the Pi

1. Insert the SD card into your Pi and power it on.
2. Wait about **5 minutes** (or grab a coffee ☕).


---

## 🔌 Step 5 – Start Your SSH Connection

Use an SSH client (e.g. **PuTTY**, **MobaXterm**, or **Terminal**) to connect to your SBC:

```bash
ssh <USER>@<SBC-IP-ADDRESS>
```

---

## 📥 Step 6 – Download and Run the Installation Script

Download and execute the **[`setup_tunnel_klipper.sh`](setup_tunnel_klipper.sh)** script directly on your SBC:

```bash
wget https://raw.githubusercontent.com/Kobra-S1/vanilla-klipper-swu/main/setup_tunnel_klipper.sh
chmod +x setup_tunnel_klipper.sh
sudo ./setup_tunnel_klipper.sh
```

The script now asks first:

* **1) Auto-detect**
* **2) Manual selection**

Manual selection currently supports:

* Raspberry Pi 4
* Raspberry Pi 5
* Raspberry Pi Compute Module 4 (CM4)
* Raspberry Pi Compute Module 5 (CM5)
* BTT Pi2 (BigTreeTech CB2)
* Raspberry Pi Zero 2 W

For **BTT Pi2**, the script configures `/boot/armbianEnv.txt` and may report that a reboot is required before `ports.service` can start.

If that happens, reboot once and run:

```bash
sudo systemctl restart ports.service
sudo systemctl status ports.service
```

Expected after successful setup: `Active: active (exited)`.

If startup fails (for example no UDC available yet), `ports.service` retries automatically with a short delay.

### USB network link

Besides the two serial ports (`/dev/ttyGS0`, `/dev/ttyGS1`), the gadget carries a network link on the same cable: `usb0` on the SBC, with the fixed address `10.55.0.1/30`, which `/opt/ports.sh` sets each time it starts the gadget. A printer running Kobrian uses it as `10.55.0.2` - its screen reaches Moonraker over the cable instead of WiFi. Printers on stock firmware ignore it.

Check after a reboot:

```bash
ip -br addr show usb0        # 10.55.0.1/30
ping -c 3 10.55.0.2          # once a Kobrian printer is connected
```

Setups from before this change had a third, unused serial port; running the script again replaces it with the network link. Both take the same USB endpoints, so every SBC that ran the old setup can run this one.

Ansible note: the Ansible setup in this repository is currently not updated for BTT Pi2 or Raspberry Pi Zero 2 W and supports only Raspberry Pi 4/5.

---

## 🧩 Step 7 – Install KIAUH

After the installation and execution of setup_tunnel_klipper.sh, **KIAUH** will automatically start.

Choose one of the following options:

* **Option 1** – to use KIAUH V6.
* **Option 3** – to use and save permanently KIAUH V6.

> ⚙️ Follow the instructions [Install Klipper](klipper_install.md)

---


## 🔧 Step 8 – Modify the Klipper Start Script

To avoid spurious issues with klippy connecting to the S1 MCUs after reboot, add these two lines into your /etc/systemd/system/klipper.service file (above ExecStart=/home/pi/klippy-env/bin/python $KLIPPER_ARGS):
```
 ExecStartPre=/bin/stty -F /dev/ttyGS0 sane
 ExecStartPre=/bin/stty -F /dev/ttyGS1 sane
```
Afterwards execute:
```
 sudo systemctl daemon-reload
 sudo systemctl restart klipper
```

---



## ✅ Done!

Once the installation is complete, your **Klipper Tunnel** setup is ready.
You can now continue with your Klipper configuration and enjoy your automated setup.

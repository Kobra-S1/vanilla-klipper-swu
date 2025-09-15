# Tunneled-Klipper App for Rinkhals on Anycubic Kobra S1

The **tunneled-klipper** app forwards the printer’s serial interface to a Raspberry Pi 4 via USB gadget mode.  
This lets you run Klipper on the RPi4 while the Kobra S1 SoC acts as a serial bridge to the MCUs.

---

## ⚠️ Important Warning

- Better **NOT** click **Enable App** in Rinkhals.  
- Only use **Start App**. Otherwise the printer config menu may may not be reachable anymore ; you’ll need SSH or an `installer.swu` to recover and disable the app.

---

## 🛠️ Requirements

- Raspberry Pi 4 (RPi4)  
- USB-C to USB-A OTG cable with an additional USB power blocker  
- Additional USB serial-gadget setup & vanilla-Klipper installation on the RPi4 (not covered here)

For details, see the **#tunneled-klipper** channel on the Rinkhals Discord.
Here you can find 2 instructions:

 -[Raspberry Setup for Tunnel](SetupRaspberryPi.md)
 
 -[Klipper install on Pi for Kobra S1](klipper_install.md)
 
---

## 🔄 Use Case

Choose tunneled-klipper if:

- You prefer running Klipper on an external RPi4 (more CPU/memory).  
- You want features not supported by the SoC build (e.g., LIS2DW12 resonance testing).

Otherwise, use [vanilla-klipper](vanilla-klipper.md) directly on the SoC.

---

## 📋 Preconditions

- Anycubic Kobra S1 (**KS1**) with **Rinkhals** already installed and running.  
- Update file from `releases/KS1/`, e.g.:
  ```
  ks1_tunneled-klipper_app_v0.3.swu
  ```

---

## 🚀 Installation Steps

1. **Prepare the update file**
   ```bash
   ks1_tunneled-klipper_app_v0.3.swu → update.swu
   ```
   Copy it to:
   ```
   aGVscF9zb3Nf/update.swu
   ```

2. **Insert the USB drive into the printer**
   - 1st beep → copying starts  
   - 2nd beep → copying finished

3. **Open the Rinkhals App Menu**
   ```
   Settings → General → Rinkhals → Manage apps
   ```
   You should now see **tunneled-klipper** listed.

---

## ⚙️ Starting Tunneled-Klipper

### Do **not** enable at boot (for now)

- Do **not** tick the checkbox next to **tunneled-klipper**.  
- Do **not** press **Enable App**.  
- If enabled, the app will auto-start at boot, but switching to the **Settings** tab can lead to “Printer not ready…” and a blocked UI.  
  To unblock the UI via SSH on the Kobra S1:
  ```bash
  cd /useremain/home/rinkhals/apps/tunneled-klipper/
  ./app.sh stop
  ```

_Screenshots:_  
![tunneled-klipper app menu](images/tunnel_app_menu.png)  
![tunneled-klipper running](images/tunnel.png)

### Start/stop the app manually

- Open the **tunneled-klipper** entry by tapping its name.  
- Press **Start App** to start it (⚠️ do **not** press **Enable App**).  
  A double-beep is confirming the app get started, another two beeps also occure if RPI is already connected and serial ports are detected.
- Use the same button to stop/restart GoKlipper as needed.

### RPi4 setup

- Install Klipper on the RPi4 as usual.  
- Create your Klipper `printer.cfg` on the RPi4:
  - Start from your existing config; comment out unsupported keys.  
  - Change `/dev/ttyS3` and `/dev/ttyS5` to the serial-gadget devices (likely `/dev/ttyGS0` and `/dev/ttyGS1`).  
  - Or use this KS1 config as a starting point: **[printer.tunneled-klipper.cfg](releases/KS1/printer.tunneled-klipper.cfg)**

- Open Mainsail in your browser.  
- Click **MCU Restart** if the connection isn’t established automatically at startup.

**Webcam from KS1 in Mainsail**

In Mainsail, click the gear icon (top-right) → scroll to **Webcams** → **ADD WEBCAM**. Add two streams, replacing `YourPrinterName` with the hostname or IP of your KS1:

- Stream URL: `http://YourPrinterName/webcam/?action=stream`  
- Snapshot URL: `http://YourPrinterName/webcam/?action=snapshot`

---

## ⚠️ Functional Notes

- To allow full MCU reconfiguration via the tunneled vanilla-Klipper, MCUs are reset at every start/stop. This causes the LED light to flicker. (Without this, changes—e.g., nozzle sensitivity—wouldn’t be possible.)

- When the app starts, it waits for two RPi serial-gadgets to appear and then uses the Linux-assigned serial-port names for the `socat` tunnels. This name detection avoids collisions with ACE-PRO-assigned `/dev/ttyACMx` names.

- RPi detection relies on the RPi gadget USB ID (tested on RPi4&RPi5  so far; other RPis may require further testing).

- The RPi can already be connected when you start the app, but you can also start it first and connect later.  
  Disconnecting/reconnecting USB while the tunneled app is running is supported. If a `socat` connection breaks due to USB interruption, the MCUs are reset; use **FIRMWARE RESTART** in Mainsail to re-establish the connection.

---

## 🔊 Sound Indications

- At app startup, a short **double beep** indicates the delayed app launcher has begun (the “real” app starts ~15s later to avoid boot-time CPU issues).  
- Then you’ll hear the **normal double beep** from GoKlipper.  
- A **three-tone beep** indicates the “real” tunneled-Klipper app has started.  
- If an RPi is already connected at startup, you’ll immediately hear **two short double beeps**, each indicating a serial-gadget was detected and a `socat` tunnel launched.  
- If USB is **disconnected** while printing, the MCUs reset and a **two-tone beep** plays when the `socat` tunnels are removed.  
- If USB is **reconnected**, another **two-tone beep** indicates the `socat` tunnels have restarted.

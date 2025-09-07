# Vanilla Klipper App for Rinkhals on Anycubic Kobra S1

This README explains how to install and enable the **vanilla Klipper (VK)** app on the Anycubic Kobra S1 running **Rinkhals**.

---

## ⚠️ WARNING

This is an **experimental vanilla-Klipper test build** for the Kobra S1, with a custom CS1237 and probing module.

- Some hardware features do **not work** (ACE Pro).  
- Some features work **only when using tunneled-klipper with an RPi4** (e.g., LIS2DW12 resonance testing).  
- Accessible only via the **Mainsail web interface** (no KlipperScreen support).  

---

## 📋 Preconditions

- Anycubic Kobra S1 (**KS1**) with **Rinkhals** already installed and running.  
- Update file from `releases/KS1/`, for example:
  ```
  ks1_vanilla_klipper_app_v0.3_update.swu
  ```

---

## 🚀 Installation Steps

1. **Prepare the update file**
   ```bash
   ks1_vanilla_klipper_app_v0.3_update.swu → update.swu
   ```
   Copy it to:
   ```
   aGVscF9zb3Nf/update.swu
   ```

2. **Insert the USB drive into the printer**
   - 1st beep → copying starts  
   - 2nd beep → copying finished  

2.1 **`printer.cfg` handling**
   - On **first install**, `printer.klipper.cfg` is installed automatically.  
   - On **reinstall/update**, Rinkhals **does not** overwrite your existing `printer.klipper.cfg`.  
     Compare the latest reference and update manually if needed. The latest version in use is here → **[printer.klipper.cfg](releases/KS1/printer.klipper.cfg)**. Use it if in doubt after updating to the latest `vanilla-klipper.swu`.

3. **Open the Rinkhals App Menu**
   ```
   Settings → General → Rinkhals → Manage apps
   ```
   You should now see **vanilla-klipper** listed.

---

## ⚙️ Starting Vanilla Klipper

### Option 1: Permanent (autostart at boot)
- Enable the checkbox next to **vanilla-klipper**.  
- Press **Enable App → Start App**.  
- The app will run automatically on every boot.

### Option 2: Temporary (until reboot)
- Open the **vanilla-klipper** entry.  
- Press **Start App** (⚠️ Do **not** press **Enable App**).  

_Screenshots:_  
![enable start app](images/4_rinkhals_manage_apps_enable_start_app.png)

---

## ⏳ First Startup

- On the first launch, a helper library is compiled — this takes **about 1 minute**.  
- VK is ready once Mainsail is fully accessible without “starting up” messages.

---

## 🗑️ Uninstall

```bash
ssh root@<printer-ip>  # password: rockchip
cd /useremain/home/rinkhals/apps/
rm -rf vanilla-klipper/
```

---

## 🛠️ Configuration Notes

Installed config files:
- `mainsail.cfg`
- `printer.klipper.cfg` (VK uses a stripped-down version of GoKlipper’s `printer.cfg`)

👉 You may delete these if not needed after uninstall.

---

## ⚠️ Functional Notes

- To allow full MCU reconfiguration via vanilla-Klipper, the MCUs are **reset at every start/stop**, which causes the LED light to flicker. (Without this, changes such as nozzle sensitivity would not be possible.)

---

## 🧾 G-code Notes

**Builds ≥ v0.3**  
It’s possible to print directly with **OrcaSlicer** / **Anycubic Next** sliced G-code — no additional startup G-code modifications in the slicer are necessary.

**Builds ≤ v0.2**  
- The OrcaSlicer KS1 profile alone will **not work**.  
- You must add proper startup G-code; otherwise you’ll see:
  ```
  Hotend too cold to extrude
  ```
  Use this as a starting point (only for older builds ≤ v0.2):  
  Startup help: → **[KS1_WIP_StartupGCode.txt](releases/KS1/KS1_WIP_StartupGCode.txt)**  
  End G-code: → **[KS1_WIP_EndGCode.txt](releases/KS1/KS1_WIP_EndGCode.txt)**  
  Copy & paste into your slicer’s Startup/End G-code sections as appropriate.
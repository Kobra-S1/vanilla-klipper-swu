# Vanilla Klipper App for Rinkhals on Anycubic Kobra S1

This readme explains how to install and enable the **vanilla Klipper (VK)** app on the Anycubic Kobra S1 running **Rinkhals**.

---

## ⚠️ WARNING !

This is an **experimental vanilla-klipper test build** for KOBRA-S1, with a custom CS1237 and probing module.

- Some hardware features do **not work** (filament runout, ACE Pro).  
- Some features work **only if using tunneled-klipper with RPi4** (e.g., LIS2DW12 resonance testing).  
- Accessible only via **Mainsail web interface** (no KlipperScreen support).  

👉 At first startup & first homing:  
Check that homing and virtual endstop switches work!  
If not → **Emergency Stop** or power off immediately.

---

## 📋 Preconditions

- Anycubic Kobra S1 (**K1S**) with **Rinkhals** already installed and running.  
- Update file from `releases/KS1/`, e.g.  
  ```
  ks1_vanilla_klipper_app_v0.2_update.swu
  ```

---

## 🚀 Installation Steps

1. **Prepare update file**
   ```bash
   ks1_vanilla_klipper_app_v0.2_update.swu → update.swu
   ```
   Copy it to:
   ```
   aGVscF9zb3Nf/update.swu
   ```

2. **Insert USB drive into printer**
   - 1st beep → copying starts  
   - 2nd beep → copying finished  

2.1 **printer.cfg**
   - If installed the first time, printer.klipper.cfg is automatically installed
   - If re-installed or updated again, Rinkhals does not automatically update/overwrite your existing printer.klipper.cfg. Check if printer.klipper.cfg contains changes against your version and update manually if necessary! Latest version I use can be found here: → [**printer.klipper.cfg**](releases/KS1/printer.klipper.cfg) use that one if in doubt after update to latest vanilla-klipper.swu


3. **Open Rinkhals App Menu**
   ```
   Settings → General → Rinkhals → Manage apps
   ```
   You should now see **`vanilla-klipper`** listed.

---

## ⚙️ Starting Vanilla Klipper

### Option 1: Permanent (autostart at boot)
- Enable checkbox next to **vanilla-klipper**
- Press **Enable App → Start App**  
- Runs automatically on every boot.

### Option 2: Temporary (until reboot)
- Open **vanilla-klipper** entry
- Press **Start App** (⚠️ Do not press Enable App)
Screenshots: ![enable start app](images/4_rinkhals_manage_apps_enable_start_app.png) 
---

## ⏳ First Startup Warning

- The first launch compiles a kernel module → takes ~1 minute.  
- VK is ready once Mainsail is fully accessible without "starting up" messages.

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
- `printer.klipper.cfg` (VK uses this stripped-down version of GoKlipper’s `printer.cfg`)

👉 You may delete them if not needed after uninstall.
---
## ⚠️ Functional notes

- To allow full reconfiguration of MCU via vanilla-klipper, MCUs are reseted at every start/stop -> Causes flickering of LED light (Without that, it would be not possible to change e.g. nozzle sensitivity or stuff like that).
---

## ⚠️ G-code Warning

- OrcaSlicer KS1 profile alone will **not work**.  
- You must add proper startup G-code, otherwise you’ll see:
  ```
  Hotend too cold to extrude
  ```

GoKlipper macros (auto-level, wipe, reversed YX homing) are not present.  
👉 Provide your own homing + startup G-code in `printer.klipper.cfg`.

Startup help: see  → [**KS1_WIP_StartupGCode.txt**](releases/KS1/KS1_WIP_StartupGCode.txt)  
[**KS1_WIP_EndGCode.txt**](releases/KS1/KS1_WIP_EndGCode.txt)  


Copy & paste into your slicer’s Startup G-code section.

---
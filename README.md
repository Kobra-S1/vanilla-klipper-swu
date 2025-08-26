# Test builds of Vanilla Klipper and Tunneled-Klipper APPs for Rinkhals on Anycubic Kobra S1

This repository contains experimental test builds of:

- **[Vanilla-Klipper](vanilla-klipper.md)** → Run Klipper natively on the Anycubic Kobra S1 SoC under Rinkhals.
- **[Tunneled-Klipper](tunneled-klipper.md)** → Instead of running Klipper on the printer SoC, forward serial comms over USB gadget mode to a Raspberry Pi 4.

---

## ⚠️ General Notes

- These builds are **experimental**.  
- Some hardware features may not work or may only function when combined with tunneled-klipper + RPi4 (e.g., LIS2DW12 resonance testing).  
- Currently only **Mainsail Web Interface** is supported (no KlipperScreen on display).

👉 Choose your setup:

- If you want Klipper directly on the printer → [**vanilla-klipper.md**](vanilla-klipper.md)  
- If you want to offload Klipper to an external RPi4 → [**tunneled-klipper.md**](tunneled-klipper.md)  

For discussion, see the **#tunneled-klipper** channel on the Rinkhals Discord.

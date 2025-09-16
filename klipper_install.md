# ⚙️ Klipper Installation on Raspberry Pi (Vanilla Klipper Tunnel)

This guide explains how to install **Klipper** on a **Raspberry Pi** using **KIAUH** and switch to the **Kobra S1 repository**.

---

## 🧩 Step 1 – Install KIAUH

Follow the official KIAUH installation guide:

🔗 [KIAUH GitHub Repository](https://github.com/dw-0/kiauh#-download-and-use-kiauh)

After running the installation commands, you will see the main KIAUH menu:

![Kiauh1](/images/Kiauh1.jpg)

---

## 🔄 Step 2 – Switch Klipper Repository to Kobra S1 Version

1. Press **`S`** → Enter  
2. Press **`1`** → Enter (Switch Klipper source)  
3. Press **`A`** → Enter (Add repository)  
4. Enter this repository URL:  

   ```
   https://github.com/Kobra-S1/klipper-kobra-s1.git
   ```

5. Press Enter  
6. When asked for the branch, enter:

   ```
   Kobra-S1-Dev
   ```

7. Confirm and **save with `Y`**  
8. Select the repository from the list (by number) and press **Enter**  
9. After switching the repository, press **`b`** to go back to the main menu

---

## 🚀 Step 3 – Install Klipper & Related Components

Now install the software you need:

- Klipper  
- Moonraker  
- Fluidd and/or Mainsail  

Once installed, you can configure everything through your **web interface** (Fluidd or Mainsail).

A KS1 printer.cfg for klipper to start with can be found here: **[printer.tunneled-klipper.cfg](releases/KS1/printer.tunneled-klipper.cfg)**

Replace the default printer.cfg (e.g. via mainsail configuration editor) with the content of that file.  

✅ That’s it — if everything went well, your Klipper setup is ready to use.

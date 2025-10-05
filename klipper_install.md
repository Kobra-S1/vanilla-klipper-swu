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

- **Klipper**  
- **Moonraker**  
- **Fluidd** and/or **Mainsail**

---

### 🖥️ Klipper Installation

Follow the prompts in the installer:

- **Number of Instances:** `1` (or as you like)  
- **Create example config?:** `Y`  
- **Overwrite existing config?:** `N`  
- **Re-create VirtualEnv?:** `N`  
- **Add user to group?:** `Y`  
- **Finish installation** 

---

### 🌙 Moonraker Installation

- **Create example config?:** `Y` 

---

### 💧 Fluidd / Mainsail Installation

- **Create example config?:** `Y` 

---

### 🌐 Accessing the Web Interface

Once installation is complete, you can configure everything via your **web interface**:

- **Fluidd/Mainsail:** `http://<RPI-IP>:80`  


> 💡 **Tip:** You can switch between Fluidd and Mainsail based on your preference. Both provide a full web-based control interface for Klipper.


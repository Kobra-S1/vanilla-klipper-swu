# ⚙️ Klipper Installation on Raspberry Pi (Vanilla Klipper Tunnel)

This guide explains how to install **Klipper** on a **Raspberry Pi** using **KIAUH** and switch to the **Kobra S1 repository**.

---

## 🧩 Step 1 – Install KIAUH
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
## 🌈 Optional – Install the Tunnel Control Script (from the User "NUKY" thank you for your work)

**Download** [tunnel_controll](tunnel_controll.sh)

If you are using a **KS1 setup**, you can optionally install the **Tunnel Control Script** to manage the **LED** and **Tunnel App** directly from your Raspberry Pi.

### 🔧 Installation
1. **Save the script**  
   Copy the file **`tunnel_controll.sh`** to your Raspberry Pi (e.g., into your home directory).

2. **Grant execution privileges**  
   Run the following commands via SSH:

   ```bash
   sudo su
   chmod +x tunnel_controll.sh
   ```

3. **Start the script**

   ```bash
   ./tunnel_controll.sh
   ```

4. **Select installation**  
   When prompted, choose:

   ```
   1) Install
   ```

5. **Enter your printer’s IP address**  
   Type in the **IP address of your printer**, *not* your Raspberry Pi.  
   Example:

   ```
   192.168.1.22
   ```

   Then press **Enter** to continue.

6. **Finish installation** ✅  
   Once complete, you can find:
   - 💡 **LED Macros** under the **Macros** section in Fluidd/Mainsail  
   - 🚇 **Tunnel Control Panel** at the **top right**, under the **Power** menu

---

### ⚙️ Features

- 💡 **LED Control** – toggle or dim tunnel lighting  
- 🔄 **Automatic Startup** – starts the control service on boot  
- 🧠 **Integration with KS1** – direct control through your web UI  

---

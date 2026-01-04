# ⚙️ Klipper Installation on Raspberry Pi (Vanilla Klipper Tunnel)

This guide explains how to install **Klipper** on a **Raspberry Pi** using **KIAUH** and switch to the **Kobra S1 repository**.

---

## 🧩 Step 1 – Install KIAUH
After running the installation commands, you will see the main KIAUH menu:

![Kiauh1](/images/Kiauh1.jpg)

---

## 🔄 Step 2 – Switch Klipper Repository to Kobra S1 Version

Update: If you installed kiauh via "setup_tunnel_klipper.sh" script, this step 2 is done automated by setup script, so the right repo is already select by default. In case you install manually, execute the below mentioned steps, otherwise its fine to skip step 2 and continue with step 3.

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

**Download** [tunnel_control](tunnel_control.sh)

To download execute in your RPi shell:
```
wget https://github.com/Kobra-S1/vanilla-klipper-swu/blob/main/tunnel_control.sh
```
If you are using a **KS1 setup**, you can optionally install the **Tunnel Control Script** to manage the **LED** and **Tunnel App** directly from your Raspberry Pi.

### 🔧 Installation
1. **Save the script**  
   Copy the file **`tunnel_control.sh`** to your Raspberry Pi (e.g., into your home directory).

2. **Grant execution privileges**  
   Run the following commands via SSH:

   ```bash
   sudo su
   chmod +x tunnel_control.sh
   ```

3. **Start the script**

   ```bash
   ./tunnel_control.sh
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
   - 🚇 **Tunnel Control Panel** at the **top right**, under the **Power** menu

# 💡 LED Control Macros

You can put the following macros in your **Printer.cfg** or in a separate include file like **Macro.cfg**.
These macros allow you to **turn the printer light ON/OFF** or **toggle it** using the Tunnel Control Script.

---

## ⚙️ Pre-requisite: Install `sshpass`

Before using the macros, ensure `sshpass` is installed on your Raspberry Pi:

```bash
sudo apt update
sudo apt install -y sshpass
```

> 💡 `sshpass` allows automated SSH commands with password authentication.

---

## 🔧 Macros

```
# ----------------------------------------
# Light Control Macros
# ----------------------------------------

[gcode_shell_command gpio_set]
command: sshpass -p 'rockchip' ssh -o StrictHostKeyChecking=no root@IPADDRESS_PRINTER "echo 1 > /sys/class/gpio/gpio117/value"
timeout: 10.0
verbose: True

[gcode_shell_command gpio_clear]
command: sshpass -p 'rockchip' ssh -o StrictHostKeyChecking=no root@IPADDRESS_PRINTER "echo 0 > /sys/class/gpio/gpio117/value"
timeout: 10.0
verbose: True

[gcode_macro LIGHT_ON]
description: Turn printer light ON
gcode:
    RUN_SHELL_COMMAND CMD=gpio_set
    RESPOND MSG="💡 Light turned ON"

[gcode_macro LIGHT_OFF]
description: Turn printer light OFF
gcode:
    RUN_SHELL_COMMAND CMD=gpio_clear
    RESPOND MSG="💡 Light turned OFF"

[gcode_macro LIGHT_TOGGLE]
description: Toggle printer light ON/OFF
variable_light_state: 0
gcode:
    {% if printer["gcode_macro LIGHT_TOGGLE"].light_state == 0 %}
        RUN_SHELL_COMMAND CMD=gpio_set
        SET_GCODE_VARIABLE MACRO=LIGHT_TOGGLE VARIABLE=light_state VALUE=1
        RESPOND MSG="💡 Light turned ON"
    {% else %}
        RUN_SHELL_COMMAND CMD=gpio_clear
        SET_GCODE_VARIABLE MACRO=LIGHT_TOGGLE VARIABLE=light_state VALUE=0
        RESPOND MSG="💡 Light turned OFF"
    {% endif %}
```

> ⚠️ **Tip:** Replace `IPADDRESS_PRINTER` with your printer's actual IP address. Make sure SSH access to the printer works.

---

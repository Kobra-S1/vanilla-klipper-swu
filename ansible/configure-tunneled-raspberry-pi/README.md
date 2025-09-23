# Klipper Raspberry Pi 4/5 Ansible Playbook

This Ansible playbook configures a Raspberry Pi 4 or Raspberry Pi 5 for use with Klipper 3D printer firmware. It sets up USB Gadget Mode to create virtual serial interfaces that Klipper can use to communicate with 3D printers.

## Overview

The playbook performs the following configurations:
- Enables SPI and configures boot settings for optimal Klipper performance
- Loads required kernel modules (`dwc2`, `libcomposite`)
- Creates a USB gadget with multiple serial ACM interfaces
- Sets up a systemd service that automatically configures USB interfaces at boot

## Structure

```
vanilla-klipper/
├── README.md                           # This file
├── inventory.yaml                      # Ansible inventory with Raspberry Pi configuration
├── playbook.yaml                       # Main playbook
├── vanilla-klipper-raspberry-pi-4/     # Ansible role for Raspberry Pi 4
│   ├── files/
│   │   ├── config.txt                  # Raspberry Pi 4 boot configuration
│   │   ├── ports.service               # Systemd service unit
│   │   └── ports.sh                    # USB gadget configuration script
│   ├── handlers/
│   │   └── main.yaml                   # Reboot handler
│   ├── tasks/
│   │   └── main.yaml                   # Main tasks of the role
│   └── templates/
│       └── modules.j2                  # Kernel modules template
└── vanilla-klipper-raspberry-pi-5/     # Ansible role for Raspberry Pi 5
    ├── files/
    │   ├── config.txt                  # Raspberry Pi 5 boot configuration
    │   ├── ports.service               # Systemd service unit
    │   └── ports.sh                    # USB gadget configuration script
    ├── handlers/
    │   └── main.yaml                   # Reboot handler
    ├── tasks/
    │   └── main.yaml                   # Main tasks of the role
    └── templates/
        └── modules.j2                  # Kernel modules template
```

## Prerequisites

- Ansible 2.9 or higher
- Raspberry Pi 4 or Raspberry Pi 5 with Raspberry Pi OS
- SSH access to the Raspberry Pi
- Sudo privileges on the Raspberry Pi

## Installation and Usage

### 1. Configure Playbook

Edit the `playbook.yaml` file and uncomment the appropriate role for your Raspberry Pi model:

**For Raspberry Pi 4:**
```yaml
- hosts: raspberrypi
  become: true
  roles:
    - vanilla-klipper-raspberry-pi-4
    # - vanilla-klipper-raspberry-pi-5
```

**For Raspberry Pi 5:**
```yaml
- hosts: raspberrypi
  become: true
  roles:
    # - vanilla-klipper-raspberry-pi-4
    - vanilla-klipper-raspberry-pi-5
```

### 2. Configure Inventory

Edit the `inventory.yaml` file and enter your Raspberry Pi details:

```yaml
all:
  hosts:
    raspberrypi:
      ansible_host: <YOUR_RASPBERRY_PI_IP>
      ansible_user: <YOUR_SSH_USER>
      ansible_port: 22
      ansible_password: <YOUR_PASSWORD>
      ansible_become: true
      # ansible_ssh_private_key_file: <YOUR_PRIVATE_KEY_FILE>
```

**Note:** For better security, use SSH keys instead of passwords.

### 3. Run Playbook

```bash
ansible-playbook -i inventory.yaml playbook.yaml
```

The playbook will automatically restart the Raspberry Pi to activate the boot configuration.

### 4. Verify Results

After reboot, the following USB devices should be available:
- `/dev/ttyACM0` - First serial interface
- `/dev/ttyACM1` - Second serial interface  
- `/dev/ttyACM2` - Third serial interface (for ACE Pro)

## Ansible Roles Details

This playbook includes two separate roles optimized for different Raspberry Pi models:

### vanilla-klipper-raspberry-pi-4 Role

Customized for **Raspberry Pi 4**:

#### Tasks
1. **Boot Configuration**: Copies optimized `config.txt` for Raspberry Pi 4
2. **Kernel Modules**: Configures `/etc/modules` with `dwc2` and `libcomposite`
3. **USB Gadget Script**: Installs the configuration script to `/opt/ports.sh`
4. **Systemd Service**: Sets up `ports.service` for automatic startup
5. **Service Activation**: Starts and enables the ports.service

#### Configuration Files
- **config.txt**: Enables SPI, optimized for 64-bit mode
- **ports.sh**: Creates USB gadget with 3 ACM serial interfaces
- **ports.service**: Systemd service unit for automatic startup

### vanilla-klipper-raspberry-pi-5 Role

Customized for **Raspberry Pi 5**:

#### Tasks
The tasks are the same as those in the Raspberry Pi 4 playbook.

#### Configuration Files
- **config.txt**: Raspberry Pi 5-specific boot configuration
- **ports.sh**: Same configuration as for Raspberry Pi 4
- **ports.service**: Same configuration as for Raspberry Pi 4

### Common Features

Both roles include:
- **Handlers**: `reboot_pi` - Restarts the Raspberry Pi after boot configuration changes
- **USB Gadget Creation**: Creates virtual serial interfaces for Klipper communication
- **Automatic Service Management**: Ensures services start on boot and restart on failure

## Troubleshooting

### USB Gadget not working
1. Check if modules are loaded:
   ```bash
   lsmod | grep -E "dwc2|libcomposite"
   ```

2. Check service status:
   ```bash
   sudo systemctl status ports.service
   ```

3. Check USB devices:
   ```bash
   ls -la /dev/ttyACM*
   ```

### Raspberry Pi won't boot
- Check `config.txt` for syntax errors
- Ensure the correct role is uncommented in `playbook.yaml` for your Pi model
- Verify that the Raspberry Pi model being used matches the selected role

### Wrong role selected
- If you're using Raspberry Pi 4, ensure `vanilla-klipper-raspberry-pi-4` is uncommented
- If you're using Raspberry Pi 5, ensure `vanilla-klipper-raspberry-pi-5` is uncommented
- Only one role should be active at a time in the playbook

## Supported Hardware

### Raspberry Pi 4 Role (`vanilla-klipper-raspberry-pi-4`)
- Raspberry Pi 4 Model B (all RAM variants)

### Raspberry Pi 5 Role (`vanilla-klipper-raspberry-pi-5`)
- Raspberry Pi 5 (all RAM variants)

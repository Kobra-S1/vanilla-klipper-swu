#!/bin/bash
set -e

# Ensure the script runs as root
if [[ $EUID -ne 0 ]]; then
    echo "Please run with sudo or as root"
    exit 1
fi

NORMAL_USER=${SUDO_USER:-$USER}

detect_target() {
    local model
    model=$(tr -d '\0' </proc/device-tree/model 2>/dev/null || true)

    case "$model" in
        *"Raspberry Pi 4"*)
            echo "pi4"
            ;;
        *"Raspberry Pi 5"*)
            echo "pi5"
            ;;
        *"Compute Module 4"*)
            echo "cm4"
            ;;
        *"Compute Module 5"*)
            echo "cm5"
            ;;
        *"BigTreeTech CB2"*|*"BTT"*|*"CB2"*)
            echo "btt_pi2"
            ;;
        *"Raspberry Pi Zero 2"*)
            echo "pi0"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

configure_pi_boot_config() {
    local block_name="$1"
    local config_file

    if [[ -f "/boot/firmware/config.txt" ]]; then
        config_file="/boot/firmware/config.txt"
    elif [[ -f "/boot/config.txt" ]]; then
        config_file="/boot/config.txt"
    else
        echo "Error: Could not find Raspberry Pi config.txt (checked /boot/firmware/config.txt and /boot/config.txt)."
        exit 1
    fi

    echo "=== Configuring ${config_file} for ${block_name} ==="
    if grep -q "^\[$block_name\]" "$config_file"; then
        if ! awk -v blk="[$block_name]" '
            /^\[/ { in_section = ($0 == blk) }
            in_section && /^dtoverlay=dwc2/ { found=1 }
            END { exit !found }
        ' "$config_file"; then
            sed -i "/^\[$block_name\]/a dtoverlay=dwc2" "$config_file"
        fi
    else
        {
            echo ""
            echo "[$block_name]"
            echo "dtoverlay=dwc2"
        } >> "$config_file"
    fi
}

configure_btt_pi2_boot_config() {
    local armbian_env="/boot/armbianEnv.txt"
    local overlay_name="rk3568-dwc3-peripheral"

    if [[ ! -f "$armbian_env" ]]; then
        echo "Error: ${armbian_env} not found. Cannot configure BTT Pi2 boot settings automatically."
        exit 1
    fi

    echo "=== Configuring ${armbian_env} for BTT Pi2 USB gadget mode ==="
    if grep -q '^overlays=' "$armbian_env"; then
        if grep -Eq "^overlays=.*\b${overlay_name}\b" "$armbian_env"; then
            echo "Overlay ${overlay_name} already present"
        else
            sed -i -E "s|^overlays=(.*)$|overlays=\\1 ${overlay_name}|" "$armbian_env"
        fi
    else
        echo "overlays=${overlay_name}" >> "$armbian_env"
    fi
}

ensure_module_line() {
    local module_name="$1"
    [[ -f /etc/modules ]] || touch /etc/modules
    grep -qxF "$module_name" /etc/modules || echo "$module_name" >> /etc/modules
}

configure_modules_for_target() {
    local target="$1"

    echo "=== Configuring /etc/modules for ${target} ==="
    if [[ "$target" == "pi4" || "$target" == "pi5" || "$target" == "pi0" || "$target" == "cm4" || "$target" == "cm5" ]]; then
        ensure_module_line "dwc2"
        ensure_module_line "libcomposite"
    elif [[ "$target" == "btt_pi2" ]]; then
        ensure_module_line "libcomposite"
        echo "Info: dwc2 is not forced on BTT Pi2 (Armbian/Rockchip may use DWC3 gadget mode)."
    fi
}

TARGET=""
TARGET_SOURCE=""

# --- Target selection mode ---
echo "Detect target automatically or select manually?"
echo "1) Auto-detect"
echo "2) Manual selection"
read -rp "Please enter number (1 or 2): " SELECTION_MODE

if [[ "$SELECTION_MODE" == "1" ]]; then
    TARGET=$(detect_target)
    if [[ "$TARGET" == "unknown" ]]; then
        echo "Auto-detection failed for this board. Please re-run and choose manual selection."
        exit 1
    fi
    TARGET_SOURCE="auto-detect"
elif [[ "$SELECTION_MODE" == "2" ]]; then
    echo "Select target board:"
    echo "1) Raspberry Pi 4"
    echo "2) Raspberry Pi 5"
    echo "3) Raspberry Pi Compute Module 4 (CM4)"
    echo "4) Raspberry Pi Compute Module 5 (CM5)"
    echo "5) BTT Pi2 (BigTreeTech CB2)"
    echo "6) Raspberry Pi Zero 2 W"
    read -rp "Please enter number (1, 2, 3, 4, 5 or 6): " TARGET_CHOICE

    if [[ "$TARGET_CHOICE" == "1" ]]; then
        TARGET="pi4"
    elif [[ "$TARGET_CHOICE" == "2" ]]; then
        TARGET="pi5"
    elif [[ "$TARGET_CHOICE" == "3" ]]; then
        TARGET="cm4"
    elif [[ "$TARGET_CHOICE" == "4" ]]; then
        TARGET="cm5"
    elif [[ "$TARGET_CHOICE" == "5" ]]; then
        TARGET="btt_pi2"
    elif [[ "$TARGET_CHOICE" == "6" ]]; then
        TARGET="pi0"
    else
        echo "Invalid selection. Please enter 1, 2, 3, 4, 5 or 6."
        exit 1
    fi
    TARGET_SOURCE="manual"
else
    echo "Invalid selection. Please enter 1 or 2."
    exit 1
fi

echo "=== Selected target: ${TARGET} (${TARGET_SOURCE}) ==="

if [[ "$TARGET" == "pi4" || "$TARGET" == "pi5" || "$TARGET" == "pi0" || "$TARGET" == "cm4" || "$TARGET" == "cm5" ]]; then
    configure_pi_boot_config "$TARGET"
elif [[ "$TARGET" == "btt_pi2" ]]; then
    configure_btt_pi2_boot_config
else
    echo "Error: Unsupported target ${TARGET}"
    exit 1
fi

configure_modules_for_target "$TARGET"

# --- Create /opt/ports.sh ---
echo "=== Creating /opt/ports.sh ==="
cat >/opt/ports.sh <<'EOF'
#!/bin/bash
set -e

modprobe libcomposite 2>/dev/null || true

cd /sys/kernel/config/usb_gadget/
mkdir -p klipper
cd klipper

if [[ -f UDC ]] && [[ -n "$(cat UDC)" ]]; then
    echo "" > UDC || true
fi

echo 0x1d6b > idVendor
echo 0x0104 > idProduct
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB

mkdir -p strings/0x409
echo 1234567890 > strings/0x409/serialnumber
echo KlipperPi > strings/0x409/manufacturer
echo VirtualSerialBridge > strings/0x409/product

mkdir -p configs/c.1/strings/0x409
echo "Config 1" > configs/c.1/strings/0x409/configuration

# Create functions (only if not present)
for i in 0 1 2; do
    mkdir -p functions/acm.usb$i
    [ -e configs/c.1/acm.usb$i ] || ln -s functions/acm.usb$i configs/c.1/
done

# Enable USB
UDC_NAME=$(ls /sys/class/udc | head -n1)
if [[ -z "$UDC_NAME" ]]; then
    echo "No UDC found. Reboot may be required after boot config changes." >&2
    exit 1
fi
echo "$UDC_NAME" > UDC
EOF

chmod +x /opt/ports.sh

# --- Create ports.service ---
echo "=== Creating /etc/systemd/system/ports.service ==="
cat >/etc/systemd/system/ports.service <<'EOF'
[Unit]
Description=USB Serial Bridge Script
After=network.target syslog.target

[Service]
Type=oneshot
ExecStart=/opt/ports.sh
User=root
WorkingDirectory=/opt
RemainAfterExit=yes
Restart=on-failure
RestartSec=3s
StartLimitIntervalSec=60
StartLimitBurst=10

[Install]
WantedBy=multi-user.target
EOF

echo "=== Enabling and starting ports.service ==="
systemctl daemon-reload
systemctl enable ports.service

if [[ -z "$(ls -A /sys/class/udc 2>/dev/null)" ]]; then
    echo "No UDC present yet. Skipping ports.service start for now."
    echo "A reboot is required to activate USB gadget mode on this board."
else
    systemctl restart ports.service
fi

# --- Install KIAUH ---
echo "=== Installing KIAUH (as user $NORMAL_USER) ==="
apt-get update
apt-get install -y git

sudo -u "$NORMAL_USER" bash <<EOF
cd ~
if [ ! -d ~/kiauh ]; then
    git clone https://github.com/dw-0/kiauh.git
fi
EOF

# --- Patch KIAUH config to use Kobra-S1 Klipper fork ---
echo "=== Patching KIAUH config for Kobra-S1 Klipper fork ==="

patch_kiauh_config_file() {
    local cfg="$1"
    [[ -f "$cfg" ]] || return 0

    # Patch only repository entries inside [klipper] section.
    sed -i '/^\[klipper\]/,/^\[/{
        /^\[klipper\]/b
        /^\[/b
        s|https://github.com/Klipper3d/klipper\(, *master\)\{0,1\}|https://github.com/Kobra-S1/klipper-kobra-s1, Kobra-S1-Dev|
    }' "$cfg"

    if grep -q 'https://github.com/Kobra-S1/klipper-kobra-s1, Kobra-S1-Dev' "$cfg"; then
        echo "Patched $cfg"
    else
        echo "Warning: Could not confirm patch in $cfg"
    fi
}

patch_kiauh_config_file "/home/$NORMAL_USER/kiauh/kiauh.cfg"
patch_kiauh_config_file "/home/$NORMAL_USER/kiauh/default.kiauh.cfg"

# --- Migrate existing Klipper checkout (if present) to Kobra-S1 fork ---
echo "=== Checking existing Klipper checkout for repository migration ==="
sudo -u "$NORMAL_USER" bash <<'EOF'
set -e

KLIPPER_DIR="$HOME/klipper"
TARGET_URL="https://github.com/Kobra-S1/klipper-kobra-s1.git"
TARGET_BRANCH="Kobra-S1-Dev"

if [[ ! -d "$KLIPPER_DIR/.git" ]]; then
    echo "No existing Klipper checkout found at $KLIPPER_DIR (nothing to migrate)."
    exit 0
fi

cd "$KLIPPER_DIR"
CURRENT_URL=$(git remote get-url origin 2>/dev/null || true)

if [[ -z "$CURRENT_URL" ]]; then
    echo "Warning: Could not determine current Klipper origin remote."
    exit 0
fi

if [[ "$CURRENT_URL" == *"Klipper3d/klipper"* ]]; then
    echo "Migrating Klipper remote to Kobra-S1 fork..."
    git remote set-url origin "$TARGET_URL"

    if git fetch origin "$TARGET_BRANCH"; then
        if git show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
            git checkout "$TARGET_BRANCH"
        else
            git checkout -B "$TARGET_BRANCH" "origin/$TARGET_BRANCH"
        fi
        echo "Existing Klipper checkout migrated to $TARGET_URL ($TARGET_BRANCH)"
    else
        echo "Warning: Failed to fetch $TARGET_BRANCH from $TARGET_URL"
    fi
else
    echo "Existing Klipper checkout already uses custom origin: $CURRENT_URL"
fi
EOF


print_post_kiauh_reminder() {
    echo ""
    echo "################################################################################################################"
    echo "After KIAUH has installed Klipper, run this once manually to optimize serial connections at klipper start:"
    echo ""
    echo "sudo sed -i '/^ExecStart=/i ExecStartPre=/bin/stty -F /dev/ttyGS1 sane' /etc/systemd/system/klipper.service"
    echo "sudo sed -i '/^ExecStart=/i ExecStartPre=/bin/stty -F /dev/ttyGS0 sane' /etc/systemd/system/klipper.service"
    echo "sudo systemctl daemon-reload"
    echo "sudo systemctl restart klipper.service"
    echo "################################################################################################################"
}

if [[ "${SKIP_KIAUH:-0}" == "1" ]]; then
    echo "SKIP_KIAUH=1 set, not launching KIAUH automatically."
else
    echo "Starting KIAUH now as user $NORMAL_USER ..."
    sleep 2
    sudo -u "$NORMAL_USER" bash -c 'cd ~/kiauh && ./kiauh.sh'
    print_post_kiauh_reminder
fi

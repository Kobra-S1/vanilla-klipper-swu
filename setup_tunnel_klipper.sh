#!/bin/bash
set -e

# Ensure the script runs as root
if [[ $EUID -ne 0 ]]; then
    echo "Please run with sudo or as root"
    exit 1
fi

NORMAL_USER=${SUDO_USER:-$USER}
CONFIG_FILE="/boot/firmware/config.txt"

# --- Query model ---
echo "Which Raspberry Pi model are you using?"
echo "1) Pi 4"
echo "2) Pi 5"
read -rp "Please enter number (1 or 2): " MODEL_CHOICE

if [[ "$MODEL_CHOICE" == "1" ]]; then
    BLOCK_NAME="pi4"
elif [[ "$MODEL_CHOICE" == "2" ]]; then
    BLOCK_NAME="pi5"
else
    echo "Invalid selection. Please enter 1 or 2."
    exit 1
fi

echo "=== Configuring config.txt for $BLOCK_NAME ==="
if grep -q "^\[$BLOCK_NAME\]" "$CONFIG_FILE"; then
    # Block exists → check dtoverlay=dwc2
    if ! awk -v blk="$BLOCK_NAME" '/^\[/{f=($0=="["blk"]")?1:0} f && /^dtoverlay=dwc2/' "$CONFIG_FILE" >/dev/null; then
        sed -i "/^\[$BLOCK_NAME\]/a dtoverlay=dwc2" "$CONFIG_FILE"
    fi
else
    # Block not present → add it
    {
        echo ""
        echo "[$BLOCK_NAME]"
        echo "dtoverlay=dwc2"
    } >> "$CONFIG_FILE"
fi

# --- Check /etc/modules ---
echo "=== Adding dwc2 and libcomposite to /etc/modules ==="
grep -qxF "dwc2" /etc/modules || echo "dwc2" >> /etc/modules
grep -qxF "libcomposite" /etc/modules || echo "libcomposite" >> /etc/modules

# --- Create /opt/ports.sh ---
echo "=== Creating /opt/ports.sh ==="
cat >/opt/ports.sh <<'EOF'
#!/bin/bash
set -e

modprobe libcomposite

cd /sys/kernel/config/usb_gadget/
mkdir -p klipper
cd klipper

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
UDC_NAME=$(ls /sys/class/udc)
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
Type=simple
ExecStart=/opt/ports.sh
User=root
WorkingDirectory=/opt
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "=== Enabling and starting ports.service ==="
systemctl daemon-reload
systemctl enable ports.service
systemctl restart ports.service

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
KIAUH_CONFIG="/home/$NORMAL_USER/kiauh/default.kiauh.cfg"
if [ -f "$KIAUH_CONFIG" ]; then
    sed -i '/\[klipper\]/,/^\[/ {
        s|https://github.com/Klipper3d/klipper|https://github.com/Kobra-S1/klipper-kobra-s1, Kobra-S1-Dev|
    }' "$KIAUH_CONFIG"
    echo "KIAUH config patched successfully"
else
    echo "Warning: KIAUH config file not found at $KIAUH_CONFIG"
fi


echo "################################################################################################################"
echo "After KIAUH has installed Klipper, run this once manually to optimize serial connections at klipper start:"
echo ""
echo "sudo sed -i '/^ExecStart=/i ExecStartPre=/bin/stty -F /dev/ttyGS1 sane' /etc/systemd/system/klipper.service"
echo "sudo sed -i '/^ExecStart=/i ExecStartPre=/bin/stty -F /dev/ttyGS0 sane' /etc/systemd/system/klipper.service"
echo "sudo systemctl daemon-reload"
echo "sudo systemctl restart klipper.service"
echo "################################################################################################################"

echo "Starting KIAUH now as user $NORMAL_USER ..."
sleep 2
sudo -u "$NORMAL_USER" bash -c 'cd ~/kiauh && ./kiauh.sh'

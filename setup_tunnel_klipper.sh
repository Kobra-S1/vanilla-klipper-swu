#!/bin/bash
set -e

# Sicherstellen, dass das Skript als root läuft
if [[ $EUID -ne 0 ]]; then
    echo "Bitte mit sudo oder als root ausführen"
    exit 1
fi

NORMAL_USER=${SUDO_USER:-$USER}
CONFIG_FILE="/boot/firmware/config.txt"

# --- Modell abfragen ---
echo "Welches Raspberry Pi Modell verwendest du?"
echo "1) Pi 4"
echo "2) Pi 5"
read -rp "Bitte Zahl eingeben (1 oder 2): " MODEL_CHOICE

if [[ "$MODEL_CHOICE" == "1" ]]; then
    BLOCK_NAME="pi4"
elif [[ "$MODEL_CHOICE" == "2" ]]; then
    BLOCK_NAME="pi5"
else
    echo "Ungültige Auswahl. Bitte 1 oder 2 eingeben."
    exit 1
fi

echo "=== Konfiguriere config.txt für $BLOCK_NAME ==="
if grep -q "^\[$BLOCK_NAME\]" "$CONFIG_FILE"; then
    # Block existiert → dtoverlay=dwc2 prüfen
    if ! awk -v blk="$BLOCK_NAME" '/^\[/{f=($0=="["blk"]")?1:0} f && /^dtoverlay=dwc2/' "$CONFIG_FILE" >/dev/null; then
        sed -i "/^\[$BLOCK_NAME\]/a dtoverlay=dwc2" "$CONFIG_FILE"
    fi
else
    # Block nicht vorhanden → hinzufügen
    {
        echo ""
        echo "[$BLOCK_NAME]"
        echo "dtoverlay=dwc2"
    } >> "$CONFIG_FILE"
fi

# --- /etc/modules prüfen ---
echo "=== Füge dwc2 und libcomposite zu /etc/modules hinzu ==="
grep -qxF "dwc2" /etc/modules || echo "dwc2" >> /etc/modules
grep -qxF "libcomposite" /etc/modules || echo "libcomposite" >> /etc/modules

# --- /opt/ports.sh erstellen ---
echo "=== Erstelle /opt/ports.sh ==="
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

# Funktionen anlegen (nur wenn nicht vorhanden)
for i in 0 1 2; do
    mkdir -p functions/acm.usb$i
    [ -e configs/c.1/acm.usb$i ] || ln -s functions/acm.usb$i configs/c.1/
done

# USB aktivieren
UDC_NAME=$(ls /sys/class/udc)
echo "$UDC_NAME" > UDC
EOF

chmod +x /opt/ports.sh

# --- ports.service erstellen ---
echo "=== Erstelle /etc/systemd/system/ports.service ==="
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

echo "=== Aktiviere und starte ports.service ==="
systemctl daemon-reload
systemctl enable ports.service
systemctl restart ports.service

# --- KIAUH installieren ---
echo "=== Installiere KIAUH (als Benutzer $NORMAL_USER) ==="
apt-get update
apt-get install -y git

sudo -u "$NORMAL_USER" bash <<EOF
cd ~
if [ ! -d ~/kiauh ]; then
    git clone https://github.com/dw-0/kiauh.git
fi
EOF

echo "=== Setup abgeschlossen ==="
echo "Starte jetzt KIAUH als Benutzer $NORMAL_USER ..."
sleep 2
sudo -u "$NORMAL_USER" bash -c 'cd ~/kiauh && ./kiauh.sh'

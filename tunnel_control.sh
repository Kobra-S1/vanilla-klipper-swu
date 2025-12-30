#!/bin/bash
set -e

SERVICE_NAME="flask-tunnel"

# --- Benutzer und Pfade ermitteln ---
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    USERNAME="$SUDO_USER"
else
    USERNAME="$(whoami)"
fi
HOME_DIR="$(getent passwd "$USERNAME" | cut -d: -f6)"
[ -z "$HOME_DIR" ] && HOME_DIR="/home/$USERNAME"

FLASK_DIR="$HOME_DIR/flask"
FLASK_SCRIPT="$FLASK_DIR/tunnel_control.py"
SYSTEMD_FILE="/etc/systemd/system/$SERVICE_NAME.service"
MOON_CFG="$HOME_DIR/printer_data/config/moonraker.conf"

[ "$(id -u)" -ne 0 ] && SUDO="sudo" || SUDO=""

install_tunnel() {
    read -p "IP Adress from Printer: " IPADDR
    [ -z "$IPADDR" ] && { echo "‚ùå Keine IP eingegeben ‚Äì Abbruch."; exit 1; }

    read -p "Port for Flask [Default 5001]: " FLASK_PORT
    [ -z "$FLASK_PORT" ] && FLASK_PORT=5001

    echo "-> Installiere ben√∂tigte Pakete..."
    $SUDO apt update
    $SUDO apt install -y python3-flask sshpass

    echo "-> Erstelle Arbeitsverzeichnis: $FLASK_DIR"
    mkdir -p "$FLASK_DIR"

    # Python-Script erzeugen
    cat > "$FLASK_SCRIPT" <<EOF
from flask import Flask, jsonify
import subprocess

app = Flask(__name__)

SSH_BASE = "sshpass -p 'rockchip' ssh root@${IPADDR} 'cd /useremain/home/rinkhals/apps/tunneled-klipper && ./app.sh'"

def run_cmd(cmd):
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=15)
        return result.stdout.strip()
    except Exception as e:
        return str(e)

@app.route("/tunnel/status", methods=["GET"])
def tunnel_status():
    output = run_cmd(f"{SSH_BASE} status")
    if "Status: started" in output:
        return jsonify({"result": "on"})
    else:
        return jsonify({"result": "off"})

@app.route("/tunnel/start", methods=["GET"])
def tunnel_start():
    run_cmd(f"{SSH_BASE} start")
    return jsonify({"result": "on"})

@app.route("/tunnel/stop", methods=["GET"])
def tunnel_stop():
    run_cmd(f"{SSH_BASE} stop")
    return jsonify({"result": "off"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=${FLASK_PORT})
EOF

    chmod +x "$FLASK_SCRIPT"
    $SUDO chown -R "$USERNAME:$USERNAME" "$FLASK_DIR"

    echo "-> Erg√§nze moonraker.conf ($MOON_CFG)"
    if ! grep -q "KlipperTunnel" "$MOON_CFG" 2>/dev/null; then
        $SUDO mkdir -p "$(dirname "$MOON_CFG")"
        $SUDO bash -c "cat >> '$MOON_CFG' <<'MOONEOF'

[power KlipperTunnel]
type: http
on_url: http://localhost:${FLASK_PORT}/tunnel/start
off_url: http://localhost:${FLASK_PORT}/tunnel/stop
status_url: http://localhost:${FLASK_PORT}/tunnel/status
locked_while_printing: true
response_template:
  {% set resp = http_request.last_response().json() %}
  {resp[\"result\"]}
MOONEOF"
        $SUDO chown "$USERNAME:$USERNAME" "$MOON_CFG"
    else
        echo "  -> Block 'KlipperTunnel' existiert schon ‚Äì √ºbersprungen."
    fi

    echo "-> Systemd-Service anlegen ($SYSTEMD_FILE)"
    $SUDO bash -c "cat > '$SYSTEMD_FILE' <<EOL
[Unit]
Description=Flask Tunnel Control
After=network.target

[Service]
Type=simple
User=$USERNAME
WorkingDirectory=$FLASK_DIR
ExecStart=/usr/bin/python3 $FLASK_SCRIPT
Restart=always

[Install]
WantedBy=multi-user.target
EOL"

    echo "-> Service aktivieren..."
    $SUDO systemctl daemon-reload
    $SUDO systemctl enable "$SERVICE_NAME"
    $SUDO systemctl restart "$SERVICE_NAME" || \
      echo "‚ùå Fehler beim Starten ‚Äì Logs mit: sudo journalctl -u $SERVICE_NAME -b"

    echo "-> Moonraker neustarten..."
    $SUDO systemctl restart moonraker || echo "‚ö†Ô∏è Moonraker-Service nicht gefunden."

    echo ""
    echo "‚úÖ Installation abgeschlossen!"
    echo "  Flask-Port: $FLASK_PORT"
    echo "  Ziel-IP:    $IPADDR"
    echo "  Service:    $SERVICE_NAME (l√§uft als $USERNAME)"
}

uninstall_tunnel() {
    echo "Ì†ΩÌª† Entferne Service..."
    $SUDO systemctl stop "$SERVICE_NAME" 2>/dev/null || true
    $SUDO systemctl disable "$SERVICE_NAME" 2>/dev/null || true
    $SUDO rm -f "$SYSTEMD_FILE"

    echo "Ì†ΩÌ∑ë Entferne Flask-Verzeichnis: $FLASK_DIR"
    $SUDO rm -rf "$FLASK_DIR"

    echo "‚ö†Ô∏è Der Block [power KlipperTunnel] in $MOON_CFG bleibt bestehen."
    echo "   Entferne ihn manuell, falls nicht mehr ben√∂tigt."

    $SUDO systemctl daemon-reload
    $SUDO systemctl restart moonraker 2>/dev/null || true

    echo "Ì†ΩÌ∑ë Deinstallation abgeschlossen."
}

echo "-----------------------------------"
echo " Flask Tunnel Setup Script"
echo "-----------------------------------"
echo "1) Install"
echo "2) Deinstall"
echo "-----------------------------------"
read -p "Bitte Auswahl eingeben [1/2]: " CHOICE

case "$CHOICE" in
    1) install_tunnel ;;
    2) uninstall_tunnel ;;
    *) echo "Ung√ºltige Auswahl!"; exit 1 ;;
esac

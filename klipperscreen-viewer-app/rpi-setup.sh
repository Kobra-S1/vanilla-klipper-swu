#!/bin/bash
# RPi-side setup script for KlipperScreen VNC (headless, for fb-vnc-viewer on printer)
# Run as root or with sudo: sudo bash rpi-setup.sh --profile ks1
set -e

WRAPPER=/usr/local/bin/klipperscreen-vnc.sh
SERVICE=/etc/systemd/system/klipperscreen-vnc.service
WIDTH=800
HEIGHT=480
PORT=5900
PROFILE=ks1
VIEWER_ROTATION=180
VNC_DEPTH=16
VNC_QUALITY=6
VNC_COMPRESS=6

usage() {
    cat <<'EOF'
Usage: sudo bash rpi-setup.sh [options]

Options:
  --profile <name>         One of: ks1, ks1m, k3, k3v2, k2p, k3m
  --printer-model <name>   Alias for --profile
  --width <pixels>         Override VNC width
  --height <pixels>        Override VNC height
  --port <port>            Override VNC port (default: 5900)
  --rotation <deg>         Recommended printer-side viewer rotation: 0/90/180/270
  --depth <bits>           VNC color depth: 16 or 24 (default: 16)
  --quality <0-9>          JPEG quality level (default: 6)
  --compress <0-9>         Compression level (default: 6)
  -h, --help               Show this help

Examples:
  sudo bash rpi-setup.sh --profile ks1
  sudo bash rpi-setup.sh --profile k3
  sudo bash rpi-setup.sh --width 480 --height 272 --rotation 270 --depth 16 --quality 5 --compress 7
EOF
}

apply_profile() {
    case "$1" in
        ks1|ks1m)
            PROFILE="$1"
            WIDTH=800
            HEIGHT=480
            VIEWER_ROTATION=180
            ;;
        k3m)
            PROFILE="$1"
            WIDTH=480
            HEIGHT=272
            VIEWER_ROTATION=90
            ;;
        k3|k3v2|k2p)
            PROFILE="$1"
            WIDTH=272
            HEIGHT=480
            VIEWER_ROTATION=90
            ;;
        *)
            echo "ERROR: Unknown profile '$1'" >&2
            usage >&2
            exit 1
            ;;
    esac
}

while [ $# -gt 0 ]; do
    case "$1" in
        --profile|--printer-model)
            [ $# -lt 2 ] && usage >&2 && exit 1
            apply_profile "$2"
            shift 2
            ;;
        --width)
            [ $# -lt 2 ] && usage >&2 && exit 1
            WIDTH="$2"
            shift 2
            ;;
        --height)
            [ $# -lt 2 ] && usage >&2 && exit 1
            HEIGHT="$2"
            shift 2
            ;;
        --port)
            [ $# -lt 2 ] && usage >&2 && exit 1
            PORT="$2"
            shift 2
            ;;
        --rotation)
            [ $# -lt 2 ] && usage >&2 && exit 1
            VIEWER_ROTATION="$2"
            shift 2
            ;;
        --depth)
            [ $# -lt 2 ] && usage >&2 && exit 1
            VNC_DEPTH="$2"
            shift 2
            ;;
        --quality)
            [ $# -lt 2 ] && usage >&2 && exit 1
            VNC_QUALITY="$2"
            shift 2
            ;;
        --compress)
            [ $# -lt 2 ] && usage >&2 && exit 1
            VNC_COMPRESS="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: Unknown argument '$1'" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [ "$VNC_DEPTH" != "16" ] && [ "$VNC_DEPTH" != "24" ]; then
    echo "ERROR: --depth must be 16 or 24 (got '$VNC_DEPTH')" >&2
    exit 1
fi

case "$VNC_QUALITY" in
    [0-9]) ;;
    *)
        echo "ERROR: --quality must be 0..9 (got '$VNC_QUALITY')" >&2
        exit 1
        ;;
esac

case "$VNC_COMPRESS" in
    [0-9]) ;;
    *)
        echo "ERROR: --compress must be 0..9 (got '$VNC_COMPRESS')" >&2
        exit 1
        ;;
esac

# --- Detect KlipperScreen venv ---
KLIPPERSCREEN_VENV=""
for candidate in /home/pi/.KlipperScreen-env /home/pi/KlipperScreen-env; do
    if [ -x "$candidate/bin/python3" ]; then
        KLIPPERSCREEN_VENV="$candidate"
        break
    fi
done
if [ -z "$KLIPPERSCREEN_VENV" ]; then
    echo "ERROR: Could not find KlipperScreen venv. Searched:"
    echo "  /home/pi/.KlipperScreen-env"
    echo "  /home/pi/KlipperScreen-env"
    echo "Set KLIPPERSCREEN_VENV manually and re-run."
    exit 1
fi

# --- Detect KlipperScreen main script ---
KLIPPERSCREEN_SCRIPT=""
for candidate in /home/pi/KlipperScreen/screen.py /home/pi/KlipperScreen/KlipperScreen.py; do
    if [ -f "$candidate" ]; then
        KLIPPERSCREEN_SCRIPT="$candidate"
        break
    fi
done
if [ -z "$KLIPPERSCREEN_SCRIPT" ]; then
    echo "ERROR: Could not find KlipperScreen main script. Searched:"
    echo "  /home/pi/KlipperScreen/screen.py"
    echo "  /home/pi/KlipperScreen/KlipperScreen.py"
    exit 1
fi

echo "=== KlipperScreen VNC setup ==="
echo "  Profile: $PROFILE"
echo "  Venv:   $KLIPPERSCREEN_VENV"
echo "  Script: $KLIPPERSCREEN_SCRIPT"
echo "  VNC:    0.0.0.0:$PORT  (${WIDTH}x${HEIGHT})"
echo "  VNC tuning: depth=$VNC_DEPTH quality=$VNC_QUALITY compress=$VNC_COMPRESS"
echo "  Viewer: rotation $VIEWER_ROTATION on printer"
echo ""

# --- Install dependencies ---
echo "[1/4] Installing packages..."
apt-get update -qq
apt-get install -y tigervnc-standalone-server

# --- Create wrapper script ---
echo "[2/4] Creating $WRAPPER..."
cat > "$WRAPPER" << EOF
#!/bin/bash
# Headless KlipperScreen VNC server for printer display
# Managed by klipperscreen-vnc.service

export DISPLAY=:1

# Start Xtigervnc (X server + VNC in one)
XTIGER_HELP="\$(Xtigervnc -help 2>&1 || true)"
VNC_ARGS="-geometry ${WIDTH}x${HEIGHT} -depth ${VNC_DEPTH} -rfbport $PORT -SecurityTypes None"

if echo "\$XTIGER_HELP" | grep -q -- "-QualityLevel"; then
    VNC_ARGS="\$VNC_ARGS -QualityLevel ${VNC_QUALITY}"
elif echo "\$XTIGER_HELP" | grep -q -- "-quality"; then
    VNC_ARGS="\$VNC_ARGS -quality ${VNC_QUALITY}"
else
    echo "Xtigervnc: quality tuning option not supported, skipping"
fi

if echo "\$XTIGER_HELP" | grep -q -- "-CompressLevel"; then
    VNC_ARGS="\$VNC_ARGS -CompressLevel ${VNC_COMPRESS}"
elif echo "\$XTIGER_HELP" | grep -q -- "-compresslevel"; then
    VNC_ARGS="\$VNC_ARGS -compresslevel ${VNC_COMPRESS}"
else
    echo "Xtigervnc: compression tuning option not supported, skipping"
fi

# shellcheck disable=SC2086
Xtigervnc :1 \$VNC_ARGS &
XTIGER_PID=\$!
sleep 2

# Disable X screensaver/blanking (prevents black screen over VNC)
DISPLAY=:1 xset s off
DISPLAY=:1 xset s noblank
DISPLAY=:1 xset -dpms 2>/dev/null

# Run KlipperScreen directly on display :1
DISPLAY=:1 $KLIPPERSCREEN_VENV/bin/python3 $KLIPPERSCREEN_SCRIPT &
KS_PID=\$!

# KlipperScreen may resize the display via xrandr after starting.
# Wait for it to settle, then force the target resolution so the VNC stream
# matches the printer's framebuffer exactly.
sleep 5
CURRENT=\$(DISPLAY=:1 xrandr 2>/dev/null | grep -oP 'current \K[0-9]+ x [0-9]+' | tr -d ' ')
if [ "\$CURRENT" != "${WIDTH}x${HEIGHT}" ]; then
    DISPLAY=:1 xrandr --newmode "${WIDTH}x${HEIGHT}_60" \$(gtf $WIDTH $HEIGHT 60 | grep Modeline | sed 's/.*"[^"]*"//') 2>/dev/null || true
    DISPLAY=:1 xrandr --addmode VNC-0 "${WIDTH}x${HEIGHT}_60" 2>/dev/null || true
    DISPLAY=:1 xrandr --output VNC-0 --mode "${WIDTH}x${HEIGHT}_60" 2>/dev/null || true
    echo "Forced VNC resolution to ${WIDTH}x${HEIGHT}"
fi

trap "kill \$KS_PID \$XTIGER_PID 2>/dev/null; wait" EXIT TERM INT
wait \$KS_PID
EOF
chmod +x "$WRAPPER"

# --- Create systemd service ---
echo "[3/4] Creating $SERVICE..."
cat > "$SERVICE" << 'EOF'
[Unit]
Description=KlipperScreen VNC (for printer display)
After=network.target moonraker.service
Wants=moonraker.service

[Service]
Type=simple
ExecStart=/usr/local/bin/klipperscreen-vnc.sh
Restart=on-failure
RestartSec=5
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

# --- Enable and start ---
echo "[4/4] Enabling and starting service..."

# Disable KlipperScreen screen blanking (prevents black screen over VNC)
KS_CONF=""
for d in /home/pi/printer_data/config /home/pi/klipper_config; do
    if [ -d "$d" ]; then
        KS_CONF="$d/KlipperScreen.conf"
        break
    fi
done
if [ -n "$KS_CONF" ]; then
    if [ ! -f "$KS_CONF" ]; then
        echo -e "[main]\nscreen_blanking = off" > "$KS_CONF"
        chown pi:pi "$KS_CONF" 2>/dev/null || true
    elif ! grep -q "screen_blanking" "$KS_CONF"; then
        sed -i '/^\[main\]/a screen_blanking = off' "$KS_CONF"
    fi
    echo "  KlipperScreen screen blanking disabled"
fi

systemctl daemon-reload
systemctl enable klipperscreen-vnc.service
systemctl restart klipperscreen-vnc.service

echo ""
echo "Done! Check status with:"
echo "  sudo journalctl -u klipperscreen-vnc.service -f"
echo ""
echo "VNC is now on port $PORT (no password)."
echo "VNC tuning: depth=$VNC_DEPTH quality=$VNC_QUALITY compress=$VNC_COMPRESS"
echo "Configured profile: $PROFILE (${WIDTH}x${HEIGHT}), recommended printer rotation: $VIEWER_ROTATION"
echo "On the printer, set VNC_HOST to this RPi's IP in:"
echo "  /useremain/rinkhals/klipperscreen-viewer.conf"
echo "Optional printer override if auto-detection is wrong:"
echo "  VIEWER_ROTATION=$VIEWER_ROTATION"
if [ "$VNC_DEPTH" = "16" ]; then
    echo "  VNC_COLOR_DEPTH=16"
else
    echo "  VNC_COLOR_DEPTH=32"
fi

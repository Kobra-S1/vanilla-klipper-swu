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

# Older setups made a third serial port that nothing uses. Its endpoints go to
# the network link below, so it is taken out of an existing gadget first.
[ -e configs/c.1/acm.usb2 ] && rm configs/c.1/acm.usb2
[ -d functions/acm.usb2 ] && rmdir functions/acm.usb2

# The two serial ports, one per printer MCU (ttyGS0, ttyGS1)
for i in 0 1; do
    mkdir -p functions/acm.usb$i
    [ -e configs/c.1/acm.usb$i ] || ln -s functions/acm.usb$i configs/c.1/
done

# Network link to the printer board (usb0 here). Linked after the serial
# ports so they keep USB interfaces 0-3, which a Kobrian board's MCU bridge
# matches on. ECM, not NCM: NCM holds small packets back to batch them.
# Fixed MACs: the default is random per bind, and the board names its
# interface after the MAC.
if [ ! -d functions/ecm.usb0 ]; then
    mkdir functions/ecm.usb0
    echo 02:4b:53:31:00:01 > functions/ecm.usb0/dev_addr
    echo 02:4b:53:31:00:02 > functions/ecm.usb0/host_addr
fi
[ -e configs/c.1/ecm.usb0 ] || ln -s functions/ecm.usb0 configs/c.1/

# Enable USB
UDC_NAME=$(ls /sys/class/udc | head -n1)
if [[ -z "$UDC_NAME" ]]; then
    echo "No UDC found. Reboot may be required after boot config changes." >&2
    exit 1
fi
echo "$UDC_NAME" > UDC

# The link's address. Set here rather than by NetworkManager, which leaves USB
# gadget interfaces unmanaged on purpose. 10.55.0.1 on this side; a printer
# running Kobrian is 10.55.0.2, stock firmware ignores the link. No gateway:
# the link carries only traffic between the two.
for _ in 1 2 3 4 5; do
    [[ -e /sys/class/net/usb0 ]] && break
    sleep 1
done
# Not fatal: ports.service restarts this script on failure, and every run
# rebinds the gadget - a missing link must not keep tearing down the MCUs'.
if ! { ip addr replace 10.55.0.1/30 dev usb0 && ip link set usb0 up; }; then
    echo "Warning: no address on usb0 - the serial ports work, the network link does not." >&2
fi

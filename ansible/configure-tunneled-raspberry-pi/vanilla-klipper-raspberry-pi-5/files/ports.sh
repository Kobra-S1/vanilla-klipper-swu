#!/bin/bash
modprobe libcomposite
cd /sys/kernel/config/usb_gadget/
mkdir -p klipper
cd klipper

echo 0x1d6b > idVendor
echo 0x0104 > idProduct
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB

mkdir -p strings/0x409
echo "1234567890" > strings/0x409/serialnumber
echo "KlipperPi" > strings/0x409/manufacturer
echo "VirtualSerialBridge" > strings/0x409/product

mkdir -p configs/c.1/strings/0x409
echo "Config 1" > configs/c.1/strings/0x409/configuration

# First serial interface
mkdir functions/acm.usb0
ln -s functions/acm.usb0 configs/c.1/

# Second serial interface
mkdir functions/acm.usb1
ln -s functions/acm.usb1 configs/c.1/

# Third serial interface for ACE Pro
mkdir functions/acm.usb2
ln -s functions/acm.usb2 configs/c.1/

# Bind to UDC
echo $(ls /sys/class/udc) > UDC
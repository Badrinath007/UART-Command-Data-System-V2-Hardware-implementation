#!/bin/bash

echo UART FIFO Project Programming   

cd "$(dirname "$0")/../RTL/output_files"

# Check file exists
if [ ! -f uart.rbf ]; then
    echo "✗ uart.rbf not found!"
    echo "Run: ./tools/compile.sh first"
    exit 1
fi

echo "→ Programming FPGA..."
unset LD_LIBRARY_PATH
sudo openFPGALoader -c usb-blaster uart.rbf

if [ $? -eq 0 ]; then
    echo "✓ Programming successful!"
    echo "✓ LEDs should activate now"
else
    echo "✗ Programming failed!"
    exit 1
fi

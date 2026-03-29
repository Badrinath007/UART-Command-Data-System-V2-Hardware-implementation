#!/bin/bash

echo UART FIFO Project Compilation

cd "$(dirname "$0")/../RTL"

# Map
echo "→ Running MAP (synthesis)..."
quartus_map uart_fifo_project
if [ $? -ne 0 ]; then
    echo "✗ MAP failed!"
    exit 1
fi

# Fit
echo "→ Running FIT (place & route)..."
quartus_fit uart_fifo_project
if [ $? -ne 0 ]; then
    echo "✗ FIT failed!"
    exit 1
fi

# Assemble
echo "→ Running ASM (assembly)..."
quartus_asm uart_fifo_project
if [ $? -ne 0 ]; then
    echo "✗ ASM failed!"
    exit 1
fi

# Convert
echo "→ Converting SOF to RBF..."
cd output_files
quartus_cpf -c uart_fifo_project.sof uart.rbf
if [ $? -ne 0 ]; then
    echo "✗ Conversion failed!"
    exit 1
fi

echo ""
echo "✓ Compilation successful!"
echo "✓ Output: output_files/uart.rbf"
echo ""
echo "Next: ./tools/program.sh"

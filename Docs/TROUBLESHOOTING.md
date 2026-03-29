# Troubleshooting Guide

## Issue: LEDs Not Lighting

### Checklist
- [ ] Board power LED is on?
- [ ] USB Blaster connected?
- [ ] Programming successful (no errors)?
- [ ] Reset button pressed?
- [ ] Correct pins assigned in .qsf?

### Diagnostic
```bash
# Check if design is loaded
# LEDs should change when reset is pressed

# If no change, verify compilation
cat output_files/uart_fifo_project.asm.rpt | tail -5
# Should show "Assembler was successful"
```

## Issue: USB Blaster Not Detected

### Solution
```bash
# 1. Unplug for 5 seconds, replug
# 2. Try different USB port (USB 2.0 preferred)
# 3. Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# 4. Verify detection
lsusb | grep -i altera
# Should show: "ID 09fb:6001 Altera"
```

## Issue: openFPGALoader Library Error

### Solution
```bash
# Clear conflicting Quartus libraries
unset LD_LIBRARY_PATH

# Try programming again
sudo openFPGALoader -c usb-blaster uart.rbf
```

## Issue: LED Pattern Incorrect

### Debug Steps
1. Check Mode (cycles every 1 second)
2. Verify active-low logic (0 = ON, 1 = OFF)
3. Test individual pins with multimeter
4. Recompile and reprogram

## Issue: UART Not Responding

### For Loopback Mode
- LEDs[0,1] should pulse continuously
- If off → UART not running → check clock

### For External UART
- Send: `0x55 0x01 0xAB 0xAC`
- Watch LED[0] (RX pulse) then LED[1] (TX pulse)
- No pulse → check pin wiring

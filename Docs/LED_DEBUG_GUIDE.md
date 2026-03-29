# LED Debug Display Guide

## Overview
5 LEDs cycle through 7 different debug modes every ~1 second.

## Mode Reference

### Mode 0: Status Flags (0-1s)
Shows system health indicators
- LED[4]: Heartbeat (slow blink)
- LED[3]: TX FIFO has data
- LED[2]: RX FIFO has data
- LED[1]: Framing error flag
- LED[0]: Checksum error flag

### Mode 1: FSM State (1-2s)
Shows protocol state machine
- LED[4]: Heartbeat
- LED[3:2]: Padding
- LED[1:0]: FSM state bits
  - 00 = IDLE
  - 01 = CMD
  - 10 = DATA
  - 11 = CHKSUM

### Mode 2: Clock Activity (2-3s)
Shows clock counter bits (all LEDs blink)
- Fastest possible LED blink = clock running

### Mode 3: FIFO Status (3-4s)
Shows FIFO full/empty flags
- LED[4]: Heartbeat
- LED[3]: TX FIFO full
- LED[2]: TX FIFO empty
- LED[1]: RX FIFO full
- LED[0]: RX FIFO empty

### Mode 4: RX/TX Activity (4-5s)
Real-time activity pulses
- LED[4]: Heartbeat
- LED[3]: RX byte received pulse
- LED[2]: TX byte sent pulse
- LED[1]: RX data available
- LED[0]: FSM wait state

### Mode 5: Combined View (5-6s)
FSM + error + data flow
- LED[4]: Heartbeat
- LED[3]: FSM[1]
- LED[2]: FSM[0]
- LED[1]: RX data available
- LED[0]: Error flag

### Mode 6: Data Flow (6-7s)
Real-time UART activity
- LED[4]: Heartbeat
- LED[3]: RX receiving
- LED[2]: TX transmitting
- LED[1]: RX FIFO level
- LED[0]: TX FIFO level

## Interpretation Examples

### "All LEDs blinking fast"
→ Mode 2 (clock activity) - system is running

### "LED[4] blinks, LED[0-1] on, LED[2-3] off"
→ Mode 0 (status) - heartbeat working, no errors, no FIFO data

### "LED[4] blinks, LED[1:0] = 01"
→ Mode 1 (FSM) - in CMD state (01 binary)

## Common LED Patterns

| Pattern | Meaning | Action |
|---------|---------|--------|
| All off | System reset or offline | Check power |
| LED[4] only | Heartbeat working | System alive ✓ |
| LED[4] + [0,1] | Status healthy | Working normally |
| LED[2] or [3] on | Error detected | Check protocol/wiring |
| Random blinking | Mode cycling | Normal behavior |

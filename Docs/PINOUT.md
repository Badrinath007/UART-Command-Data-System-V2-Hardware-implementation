# Pin Assignment Reference

## Summary Table

| Signal | Pin | Type | Voltage | Board |
|--------|-----|------|---------|-------|
| clk | PIN_23 | IN | 3.3V | 50MHz osc |
| rst_n | PIN_28 | IN | 3.3V | Reset btn |
| uart_rx | PIN_127 | IN | 3.3V | Serial RX |
| uart_tx | PIN_46 | OUT | 3.3V | Serial TX |
| leds[0] | PIN_1 | OUT | 3.3V | Green LED |
| leds[1] | PIN_2 | OUT | 3.3V | Green LED |
| leds[2] | PIN_3 | OUT | 3.3V | Green LED |
| leds[3] | PIN_7 | OUT | 3.3V | Green LED |
| leds[4] | PIN_11 | OUT | 3.3V | Green LED |

## LED Wiring Diagram
    3.3V
     │
┌────┴────┐
│  220Ω   │
└────┬────┘
     │  
  ░░░░░░░░  (LED)
     │
    GND
FPGA PIN ──[ 220Ω ]──┬── LED Anode (long)
└── GND (Cathode)

## Voltage Standards
- All pins: **3.3V LVCMOS**
- No 5V tolerance - board is 3.3V only

## Clock Source
- **PIN_23:** External 50MHz oscillator
- Always active when board powered
- No configuration needed

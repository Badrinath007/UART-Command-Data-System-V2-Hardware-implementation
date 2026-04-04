# UART Command-Data System with FIFO and LED Debug Display

> A complete UART communication system with dual FIFOs, protocol FSM, and real-time 5-LED debug visualization on Cyclone IV FPGA

![Status](https://img.shields.io/badge/Status-Working-brightgreen)
![FPGA](https://img.shields.io/badge/FPGA-Cyclone%20IV%20EP4CE22C8-blue)
![Language](https://img.shields.io/badge/Language-Verilog-orange)
![Tool](https://img.shields.io/badge/Tool-Quartus%20Prime%20Lite%2018.1-blueviolet)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Hardware Setup](#hardware-setup)
- [Project Structure](#project-structure)
- [RTL Architecture](#rtl-architecture)
- [LED Debug Display](#led-debug-display)
- [Getting Started](#getting-started)
- [Programming the FPGA](#programming-the-fpga)
- [Testing](#testing)
- [Protocol Specification](#protocol-specification)
- [Troubleshooting](#troubleshooting)
- [Future Enhancements](#future-enhancements)

---

## 🎯 Overview

This project implements a **Complete UART communication system** with the following capabilities:

- **Dual FIFOs** for RX (16 bytes) and TX (16 bytes) buffering
- **Protocol FSM** for command-data-checksum validation
- **5-LED Rich Debug Display** showing system state in real-time
- **Loopback Mode** for self-testing (or disable for external UART)
- **16x UART Oversampling** at 115200 baud rate
- **Real-time LED Multiplexing** cycling through 7 debug views

### Target Hardware
- **FPGA:** Altera/Intel Cyclone IV EP4CE22C8N
- **Programmer:** USB Blaster JTAG
- **Development Environment:** Quartus Prime Lite 18.1
- **Synthesis Tool:** Intel/Altera Flow

---

## ✨ Features

### Core UART Features
- ✅ Full-duplex UART (RX + TX)
- ✅ 115200 baud rate, 8N1 configuration
- ✅ 16x oversampling for robust reception
- ✅ Framing error detection
- ✅ Checksum validation protocol

### FIFO Buffers
- ✅ Dual independent FIFOs (RX & TX)
- ✅ 16-byte depth each
- ✅ Full/empty/almost-full/almost-empty flags
- ✅ Data count output

### Protocol FSM
```
ST_IDLE (wait for 0x55 sync) 
  ↓
ST_CMD (read command byte)
  ↓
ST_DATA (read data byte)
  ↓
ST_CHKSUM (verify sum = CMD + DATA)
  ↓
ST_IDLE (process or error)
```

### Debug Display
5 LEDs with **7 multiplexed modes** (~1 second per mode):
- **Mode 0:** Status flags (errors, FIFO activity)
- **Mode 1:** FSM state (2-bit protocol state)
- **Mode 2:** Clock counter (activity visualization)
- **Mode 3:** FIFO full/empty status
- **Mode 4:** RX/TX activity pulses
- **Mode 5:** Combined FSM + data flow
- **Mode 6:** Real-time UART activity

---

## 🔌 Hardware Setup

### Board Configuration
```
Cyclone IV EP4CE22C8N (Terasic DE-SoC or similar)
├── Clock (50MHz)
│   └── PIN_23 (on-board oscillator)
├── Reset
│   └── PIN_28 (on-board reset button)
├── UART Interface
│   ├── RX: PIN_127
│   └── TX: PIN_46
└── Status LEDs (5x)
    ├── LED[0]: PIN_1
    ├── LED[1]: PIN_2
    ├── LED[2]: PIN_3
    ├── LED[3]: PIN_7
    └── LED[4]: PIN_11
```

### LED Wiring
```
┌──────────────┐
│  FPGA Pin    │
│  (e.g. PIN1) ├──[ 220Ω ]──┬── LED Anode (long leg)
│              │             └── GND (Cathode)
└──────────────┘
```

**Note:** LEDs are **active-low** (GND = ON, 3.3V = OFF)

---

## 📁 Project Structure

```
UART-Command-Data-System-V2/
├── README.md                          # This file
├── RTL/                               # Verilog source files
│   ├── baud_gen_fixed.v              # Baud rate generator (16x clock)
│   ├── fifo.v                        # Parameterizable dual-port FIFO
│   ├── uart_rx.v                     # UART receiver with oversampling
│   ├── uart_tx_fixed.v               # UART transmitter
│   ├── uart_top_with_fifo.v          # Top module with FSM + debug
│   ├── uart_fifo_project.qpf         # Quartus project file
│   ├── uart_fifo_project.qsf         # Project settings & pin assignments
│   └── output_files/
│       ├── uart_fifo_project.sof     # SRAM bitstream
│       └── uart.rbf                  # Raw binary format (for openFPGALoader)
├── docs/                              # Documentation
│   ├── PROTOCOL.md                   # Protocol specification
│   ├── LED_DEBUG_GUIDE.md           # LED display modes explained
│   ├── PINOUT.md                    # Detailed pin assignments
│   └── TROUBLESHOOTING.md           # Common issues & solutions
├── images/                            # Hardware photos
│   ├── board_overview.jpg
│   ├── led_demonstration.jpg
│   └── jtag_connection.jpg
├── videos/                            # Demo videos
│   ├── led_blinking_demo.mp4
│   ├── protocol_test.mp4
│   └── loopback_test.mp4
└── tools/                             # Helper scripts
    ├── compile.sh                    # One-command compilation
    ├── program.sh                    # One-command programming
    └── verify_pinout.sh              # Pin assignment verification
```

---

## 🏗️ RTL Architecture

### Block Diagram
```
┌─────────────────────────────────────────────────────┐
│                  uart_top_with_fifo                 │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────┐    ┌──────────────┐              │
│  │ baud_gen     │───→│ uart_rx      │              │
│  │ (16x tick)   │    │ (oversampl.) │──→┌───┐     │
│  └──────────────┘    └──────────────┘   │RX │     │
│       │                                  │FIF│     │
│       │              ┌──────────────┐    │O  │     │
│       └─────────────→│ uart_tx      │    └───┘     │
│                      │ (serial out) │               │
│                      └──────────────┘    ┌───┐     │
│         ┌─────────────────────────────→  │TX │     │
│         │                                │FIF│     │
│  ┌──────┴──────┐                        │O  │     │
│  │  FSM        │                        └───┘     │
│  │  (Protocol) │                                  │
│  │  (Checksum) │──→ [error_led]                   │
│  └─────────────┘                                  │
│         │                                         │
│         └──→ [LED Multiplexer] ──→ [5 LEDs]      │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Module Descriptions

#### `baud_gen_fixed.v`
- **Purpose:** Generate 16x oversampling clock for UART
- **Parameters:** CLK_FREQ (50MHz), BAUD (115200)
- **Output:** `tick` pulse at 16 × baud rate
- **Size:** ~27-bit counter

#### `uart_rx.v`
- **Purpose:** Receive serial data with framing detection
- **States:** IDLE → START → DATA → STOP → DONE
- **Outputs:** `rx_data`, `rx_done`, `framing_err`
- **Sampling:** 16 clocks per bit (3 middle samples)

#### `uart_tx_fixed.v`
- **Purpose:** Transmit serial data
- **States:** IDLE → START → DATA → STOP
- **Inputs:** `tx_data`, `tx_start`
- **Outputs:** `tx`, `tx_done`, `tx_busy`

#### `fifo.v`
- **Purpose:** Dual-port synchronous FIFO buffer
- **Depth:** 16 bytes (parameterizable)
- **Features:** Full, empty, almost-full flags, data count
- **Style:** Write-increment, read-increment pointers

#### `uart_top_with_fifo.v`
- **Purpose:** Top-level integration + FSM + debug
- **FSM States:** IDLE → CMD → DATA → CHKSUM
- **Loopback Mode:** Internal TX→RX for self-test
- **Debug:** 7 LED multiplexing modes

---

## 💡 LED Debug Display

### How It Works

Every ~1 second, the LED display cycles through different views:

```
Time    Mode    LED[4]       LED[3]       LED[2]       LED[1]       LED[0]
────────────────────────────────────────────────────────────────────────────
0-1s    0       Heartbeat    TX FIFO      RX FIFO      Framing      Checksum
        (Status)             activity     activity     error        error
        
1-2s    1       Heartbeat    FSM[1]       FSM[0]       FSM[0]       FSM[0]
        (FSM)    blink        bit 1        bit 0        bit 0        bit 0
        
2-3s    2       Clock[25]    Clock[24]    Clock[23]    Clock[22]    Clock[21]
        (Activity)           (fast patterns show clock running)
        
3-4s    3       Heartbeat    TX full      TX empty     RX full      RX empty
        (FIFO)
        
4-5s    4       Heartbeat    RX tick      TX tick      RX data      FSM wait
        (Activity)
        
5-6s    5       Heartbeat    FSM[1]       FSM[0]       RX data      Error
        (Combined)
        
6-7s    6       Heartbeat    RX receive   TX transmit  RX level     TX level
        (Data flow)
        
7-8s    (cycle repeats)
```

### LED Logic (Active-Low)

```verilog
// 0 = LED ON (inverted)
// 1 = LED OFF (inverted)

leds[0] = ~checksum_error;   // OFF when error occurs
leds[1] = ~framing_err;      // OFF when frame error
leds[2] = ~rx_fifo_empty;    // ON when RX has data
leds[3] = ~tx_fifo_empty;    // ON when TX has data
leds[4] = ~heartbeat;        // Blinks continuously
```

---

## 🚀 Getting Started

### Prerequisites
- Quartus Prime Lite 18.1
- openFPGALoader or Quartus Programmer
- USB Blaster JTAG programmer
- Cyclone IV EP4CE22C8 FPGA board
- Linux/WSL environment (Ubuntu 18.04+)
- VirtualBox with Ubuntu 20.04( Recommended)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/UART-Command-Data-System-V2.git
cd UART-Command-Data-System-V2/RTL

# Verify tools installed
quartus_map --version
openFPGALoader --version
```

---

## 💻 Programming the FPGA

### Method 1: openFPGALoader (Recommended)

```bash
# Compile
cd RTL
quartus_map uart_fifo_project
quartus_fit uart_fifo_project
quartus_asm uart_fifo_project

# Convert to RBF format
cd output_files
quartus_cpf -c uart_fifo_project.sof uart.rbf

# Program FPGA
unset LD_LIBRARY_PATH
sudo openFPGALoader -c usb-blaster uart.rbf
```

### Method 2: Quartus Programmer

```bash
cd output_files
quartus_pgm -c "USB-Blaster" -m JTAG -o "p;uart_fifo_project.sof"
```

### Method 3: One-Command Script

```bash
cd RTL
bash ../tools/program.sh
```

---

## 🧪 Testing

### Loopback Test (Self-Test)
```
Expected Behavior:
✅ PIN 11 (LED[4]) blinks continuously (heartbeat)
✅ PIN 1-2 solid ON (RX/TX activity in loopback)
✅ PIN 3, 7 OFF (no errors)

This confirms:
- Clock is running
- UART is transmitting & receiving
- FIFO is cycling data correctly
- No communication errors
```

### External UART Test

**Prerequisites:**
- USB-to-Serial adapter (CH340, FT232, etc.)
- 3-wire connection (RX, TX, GND)

**Wiring:**
```
USB-Serial RX  → FPGA PIN_127 (uart_rx)
USB-Serial TX  → FPGA PIN_46  (uart_tx)
USB-Serial GND → FPGA GND
```

**Test Protocol:**
```
Send: 0x55 0x01 0xAB 0xAC
      (SYNC, CMD=01, DATA=AB, CHECKSUM=AC)

Expected Response:
✅ LED[0-1] pulse (RX activity, then TX echo)
✅ LED[2-3] stay OFF (no errors, FIFO transitional)
✅ LED[4] continues heartbeat
```

### Python Test Script

```python
import serial
import time

ser = serial.Serial('/dev/ttyUSB0', 115200, timeout=1)
time.sleep(0.5)

# Send test packet
packet = bytes([0x55, 0x01, 0xAB, 0xAC])
ser.write(packet)
print(f"Sent: {' '.join(f'{b:02X}' for b in packet)}")

# Observe LEDs:
# - LED[0] should pulse (RX received byte)
# - LED[1] should pulse (TX transmit response)

time.sleep(1)
ser.close()
```

---

## 📡 Protocol Specification

### Frame Format
```
┌────────┬─────────┬──────────┬──────────┐
│ SYNC   │ COMMAND │ DATA     │ CHECKSUM │
├────────┼─────────┼──────────┼──────────┤
│ 0x55   │ 1 byte  │ 1 byte   │ 1 byte   │
│        │ (CMD)   │ (DATA)   │ (SUM)    │
└────────┴─────────┴──────────┴──────────┘

Checksum = (CMD + DATA) & 0xFF
```

### Command Examples
```
Write Register:
  0x55 0x01 0xAB 0xAC
  (SYNC, CMD=0x01, DATA=0xAB, CHECKSUM=0xAC)
  Effect: reg_file ← 0xAB

Read Status:
  0x55 0x02 0x00 0x02
  (SYNC, CMD=0x02, DATA=0x00, CHECKSUM=0x02)
  Effect: Return status

Invalid Checksum (triggers error):
  0x55 0x01 0xAB 0xFF
  (Wrong checksum = 0xFF, expected 0xAC)
  Effect: error_led ← 1
```

---

## 🐛 Troubleshooting

### LEDs Not Lighting Up
```
✓ Check power supply to board (power LED should be on)
✓ Verify pin assignments match physical board layout
✓ Test with simple clock divider (no FSM dependencies)
✓ Measure voltage on LED pins (should see ~0-3.3V transitions)
```

### USB Blaster Not Detected
```
✓ Reseat USB cable, try different USB 2.0 port
✓ Check udev rules: ls -la /etc/udev/rules.d/51-altera.rules
✓ Kill JTAG daemon: sudo killall -9 jtagd
✓ Verify device: lsusb | grep -i altera
```

### openFPGALoader Library Conflict
```
Solution: unset LD_LIBRARY_PATH
$ unset LD_LIBRARY_PATH
$ openFPGALoader -c usb-blaster uart.rbf
```

### UART Data Not Received
```
✓ Check baud rate (must be exactly 115200)
✓ Verify RX/TX pins not swapped
✓ Test loopback mode first (disable external connection)
✓ Check signal integrity (use oscilloscope if available)
```

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for detailed solutions.

---

## 🚧 Future Enhancements

- [ ] Add 7-segment display decoder for numeric readout
- [ ] Implement multiple UART channels (parallel RX/TX)
- [ ] Add I²C/SPI protocol support
- [ ] Wireless connectivity (Bluetooth module integration)
- [ ] SD card logging of UART traffic
- [ ] Web dashboard for remote monitoring
- [ ] Automated test suite with Python

---

## 📊 Performance Specifications

| Parameter | Value | Notes |
|-----------|-------|-------|
| Clock Frequency | 50 MHz | On-board oscillator |
| UART Baud Rate | 115200 | 16x oversampling |
| Max Throughput | ~14.4 kB/s | Limited by UART speed |
| RX FIFO Depth | 16 bytes | Configurable |
| TX FIFO Depth | 16 bytes | Configurable |
| Protocol Overhead | 4 bytes minimum | SYNC + CMD + DATA + CHECKSUM |
| Latency (RX→FIFO) | <2 ms | Depends on UART frame time |
| LED Update Rate | ~1 second per mode | 7 modes cycle |

---

# Demo

[UART Hardware Demo](https://github.com/Badrinath007/UART-Command-Data-System-V2-Hardware-implementation/raw/main/Assets/UART_Demo.mp4)


![Altera_USB_Blaster](https://github.com/user-attachments/assets/b25c4de1-855b-4b34-b705-e33f35fae76e)


![Cyclone_iv](https://github.com/user-attachments/assets/58547907-aa26-44f6-a024-fe5cefebbecc)


![Cyclone_iv_fpga](https://github.com/user-attachments/assets/7a3dc232-6e5d-4f7a-a2c3-fefde0f19edd)

---

## 📝 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Authors

- **Badrinath Ayyamperumal** - Initial implementation
- Contributions welcome via pull requests!

---

## 🙏 Acknowledgments

- Altera/Intel for Cyclone IV FPGA and Quartus tools
- openFPGALoader community for cross-platform programming
- Community feedback and testing

---

## 📞 Support & Contact

- 🐛 **Issues:** Open a GitHub issue for bugs
- 💬 **Discussions:** Start a discussion for questions
- 📧 **Email:** [ra.badrinath@gmail.com](mailto:your-email@example.com)

---

**Last Updated:** 2026-03-29  
**Status:** ✅ Fully Functional | ✅ Tested on Hardware | ✅ Production Ready

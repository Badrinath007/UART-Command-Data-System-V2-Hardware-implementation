See [TROUBLESHOOTING.md](https://github.com/Badrinath007/UART-Command-Data-System-V2-Hardware-implementation/blob/main/Docs/TROUBLESHOOTING.md) for detailed solutions.

---

## 📊 Performance Specifications

| Parameter         | Value              | Notes                        |
| ----------------- | ------------------ | ---------------------------- |
| Clock Frequency   | 50 MHz             | On-board oscillator          |
| UART Baud Rate    | 115200             | 16x oversampling             |
| Max Throughput    | ~14.4 kB/s         | Limited by UART speed        |
| RX FIFO Depth     | 16 bytes           | Configurable                 |
| TX FIFO Depth     | 16 bytes           | Configurable                 |
| Protocol Overhead | 4 bytes minimum    | SYNC + CMD + DATA + CHECKSUM |
| Latency (RX→FIFO) | <2 ms              | Depends on UART frame time   |
| LED Update Rate   | ~1 second per mode | 7 modes cycle                |

---

# Demo

[UART Hardware Demo](https://github.com/Badrinath007/UART-Command-Data-System-V2-Hardware-implementation/raw/main/Demo.mp4)

---

## 📝 License

This project is licensed under the MIT License - see [LICENSE](https://github.com/Badrinath007/UART-Command-Data-System-V2-Hardware-implementation/blob/main/LICENSE) file for details.

---

## 👨‍💻 Authors

- **Badrinath Ayyamperumal** - Sole implementation

---

## 🙏 Acknowledgments

- Altera/Intel for Cyclone IV FPGA and Quartus tools
- openFPGALoader community for cross-platform programming

---

## 📞 Support & Contact

- 🐛 **Issues:** Open a GitHub issue for bugs
- 💬 **Discussions:** Start a discussion for questions
- 📧 **Email:** [ra.badrinath@gmail.com](mailto:ra.badrinath@gmail.com)

---

**Last Updated:** 2026-04-22
**Status:** ✅ Fully Functional | ✅ Tested on Hardware | ✅ Production Ready

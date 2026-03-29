# Protocol Specification

## Frame Format
┌────────┬──────────┬─────────┬──────────┐
│ SYNC   │ COMMAND  │ DATA    │ CHECKSUM │
├────────┼──────────┼─────────┼──────────┤
│ 0x55   │ 1 byte   │ 1 byte  │ 1 byte   │
└────────┴──────────┴─────────┴──────────┘

### Checksum Calculation
Checksum = (COMMAND + DATA) & 0xFF

### Command Examples

| Command | Data | Checksum | Purpose |
|---------|------|----------|---------|
| 0x01 | 0xAB | 0xAC | Write to register |
| 0x02 | 0x00 | 0x02 | Read status |
| 0xFF | 0x00 | 0xFF | Reset |

### Error Handling
- **Framing Error:** Stop bit = 0 (indicates corrupted frame)
- **Checksum Error:** Calculated sum ≠ received checksum
- Both trigger LED[3] and LED[2] respectively

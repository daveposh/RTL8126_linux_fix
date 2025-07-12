# Realtek RTL8126 Power Management Fix

## Overview

This repository contains a solution for fixing slow network performance issues with the Realtek RTL8126 5G Ethernet adapter on Linux systems. The problem is caused by power management features that can interfere with network performance.

## Problem Description

The Realtek RTL8126 network adapter can experience significant performance degradation due to various power management features:

- **Energy Efficient Ethernet (EEE)** - Can cause latency spikes and reduced throughput
- **Wake-on-LAN** - May interfere with normal operation
- **PCIe Power Management** - Can cause the device to enter power-saving states
- **Auto-suspend** - May cause connectivity issues

## Solution

This fix automatically disables all power management features for the Realtek RTL8126 adapter at boot time, ensuring consistent network performance.

## Files Included

- `fix-realtek-power.sh` - Main script that disables power management features
- `realtek-power-fix.service` - Systemd service file for automatic execution at boot
- `README.md` - This documentation file

## Installation

### Prerequisites

- Linux system with systemd
- Realtek RTL8126 network adapter
- Root/sudo access

### Installation Steps

1. **Make the script executable:**
   ```bash
   chmod +x fix-realtek-power.sh
   ```

2. **Install the script to system directory:**
   ```bash
   sudo cp fix-realtek-power.sh /usr/local/bin/
   ```

3. **Install the systemd service:**
   ```bash
   sudo cp realtek-power-fix.service /etc/systemd/system/
   ```

4. **Reload systemd and enable the service:**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable realtek-power-fix.service
   ```

5. **Start the service immediately:**
   ```bash
   sudo systemctl start realtek-power-fix.service
   ```

## What the Script Does

The `fix-realtek-power.sh` script performs the following actions:

1. **Auto-detects** the Realtek RTL8126 interface by checking vendor ID (0x10ec) and device ID (0x8126)
2. **Disables EEE** using `ethtool --set-eee enp11s0 eee off`
3. **Disables Wake-on-LAN** using `ethtool -s enp11s0 wol d`
4. **Disables PCIe power wakeup** by writing "disabled" to `/sys/class/net/enp11s0/device/power/wakeup`
5. **Sets power control to "on"** by writing "on" to `/sys/class/net/enp11s0/device/power/control`
6. **Brings the interface up** if it's down
7. **Logs all actions** to `/var/log/realtek-power-fix.log`

## Verification

### Check Service Status
```bash
sudo systemctl status realtek-power-fix.service
```

### View Log File
```bash
cat /var/log/realtek-power-fix.log
```

### Manual Verification
```bash
# Check EEE status
sudo ethtool --show-eee enp11s0

# Check Wake-on-LAN status
sudo ethtool enp11s0 | grep -i wake

# Check power wakeup status
cat /sys/class/net/enp11s0/device/power/wakeup

# Check power control status
cat /sys/class/net/enp11s0/device/power/control
```

## Troubleshooting

### Service Not Starting
If the service fails to start, check the logs:
```bash
sudo journalctl -u realtek-power-fix.service
```

### Interface Not Found
If the script can't find the Realtek interface, verify the device:
```bash
lspci | grep -i realtek
```

### Manual Execution
You can run the script manually to test:
```bash
sudo /usr/local/bin/fix-realtek-power.sh
```

## Uninstallation

To remove the fix:

1. **Disable and stop the service:**
   ```bash
   sudo systemctl disable realtek-power-fix.service
   sudo systemctl stop realtek-power-fix.service
   ```

2. **Remove the files:**
   ```bash
   sudo rm /usr/local/bin/fix-realtek-power.sh
   sudo rm /etc/systemd/system/realtek-power-fix.service
   sudo systemctl daemon-reload
   ```

3. **Remove the log file (optional):**
   ```bash
   sudo rm /var/log/realtek-power-fix.log
   ```

## Affected Motherboards

The Realtek RTL8126 5G Ethernet adapter is commonly found on the following motherboards and may experience power management issues:

### ASUS Motherboards
- **ROG STRIX B760-F GAMING WIFI**
- **ROG STRIX B760-I GAMING WIFI**
- **ROG STRIX B760-A GAMING WIFI**
- **ROG STRIX B760-G GAMING WIFI**
- **ROG STRIX B760-E GAMING WIFI**
- **ROG STRIX Z790-F GAMING WIFI**
- **ROG STRIX Z790-I GAMING WIFI**
- **ROG STRIX Z790-A GAMING WIFI**
- **ROG STRIX Z790-E GAMING WIFI**
- **ROG STRIX Z790-H GAMING WIFI**
- **ROG STRIX Z790-G GAMING WIFI**
- **TUF GAMING B760-PLUS WIFI**
- **TUF GAMING B760M-PLUS WIFI**
- **TUF GAMING Z790-PLUS WIFI**
- **TUF GAMING Z790-PRO WIFI**
- **PRIME B760-PLUS WIFI**
- **PRIME B760M-A WIFI**
- **PRIME Z790-P WIFI**
- **PRIME Z790-A WIFI**

### MSI Motherboards
- **MPG B760I EDGE WIFI**
- **MPG B760 EDGE WIFI**
- **MPG Z790I EDGE WIFI**
- **MPG Z790 EDGE WIFI**
- **MEG Z790I UNIFY**
- **MEG Z790 ACE**
- **MEG Z790 GODLIKE**
- **PRO B760M-P WIFI**
- **PRO B760-P WIFI**
- **PRO Z790-P WIFI**
- **PRO Z790-A WIFI**

### Gigabyte Motherboards
- **B760 AORUS ELITE AX**
- **B760 AORUS ELITE AX DDR4**
- **B760 AORUS PRO AX**
- **B760 AORUS PRO AX DDR4**
- **B760I AORUS PRO AX**
- **Z790 AORUS ELITE AX**
- **Z790 AORUS ELITE AX DDR4**
- **Z790 AORUS PRO AX**
- **Z790 AORUS PRO AX DDR4**
- **Z790I AORUS ULTRA**
- **Z790 AORUS MASTER**
- **Z790 AORUS XTREME**

### ASRock Motherboards
- **B760M Steel Legend WiFi**
- **B760 Pro RS WiFi**
- **B760 Pro RS/D4 WiFi**
- **Z790 Steel Legend WiFi**
- **Z790 Pro RS WiFi**
- **Z790 Pro RS/D4 WiFi**
- **Z790 PG Lightning WiFi**
- **Z790 PG Riptide WiFi**

### Other Manufacturers
- **Biostar B760GTN**
- **Biostar Z790GTN**
- **Colorful B760I FROZEN WIFI V20**
- **Colorful Z790I FROZEN WIFI V20**

### Note
This list is not exhaustive. The RTL8126 adapter may be present on other motherboards not listed here. You can verify if your system has this adapter by running:
```bash
lspci | grep -i realtek
```

## System Requirements

- **Kernel:** Linux 2.6.x or later (tested on 6.11.0-29-generic)
- **Distribution:** Ubuntu/Kubuntu 24.04 LTS (tested)
- **Hardware:** Realtek RTL8126 5G Ethernet adapter
- **Tools:** ethtool, ip, systemd

## Performance Impact

After applying this fix, you should experience:

- **Consistent network performance** without intermittent slowdowns
- **Reduced latency** during network operations
- **Stable connection** without power management interference
- **Full 5Gbps capability** when connected to compatible equipment

## Notes

- This fix is specific to the Realtek RTL8126 adapter
- The script automatically detects the correct interface
- All changes are logged for troubleshooting
- The service runs after network initialization
- Power management features are disabled but can be re-enabled manually if needed

## License

This fix is provided as-is for educational and troubleshooting purposes.

## Support

For issues related to this fix, check the log file at `/var/log/realtek-power-fix.log` for detailed information about what actions were taken and any errors encountered. 
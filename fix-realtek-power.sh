#!/bin/bash

# Script to disable power management for Realtek RTL8126 NIC
# This fixes slow network performance issues caused by power management

LOG_FILE="/var/log/realtek-power-fix.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "Starting Realtek RTL8126 power management fix"

# Find the Realtek RTL8126 interface
REALTEK_INTERFACE=""
for interface in /sys/class/net/*; do
    if [ -d "$interface" ] && [ -f "$interface/device/vendor" ]; then
        vendor=$(cat "$interface/device/vendor" 2>/dev/null)
        device=$(cat "$interface/device/device" 2>/dev/null)
        if [ "$vendor" = "0x10ec" ] && [ "$device" = "0x8126" ]; then
            REALTEK_INTERFACE=$(basename "$interface")
            log_message "Found Realtek RTL8126 interface: $REALTEK_INTERFACE"
            break
        fi
    fi
done

if [ -z "$REALTEK_INTERFACE" ]; then
    log_message "ERROR: Realtek RTL8126 interface not found"
    exit 1
fi

# Wait for interface to be ready
sleep 2

# Disable EEE (Energy Efficient Ethernet)
if command -v ethtool >/dev/null 2>&1; then
    log_message "Disabling EEE for $REALTEK_INTERFACE"
    ethtool --set-eee "$REALTEK_INTERFACE" eee off 2>/dev/null
    if [ $? -eq 0 ]; then
        log_message "EEE disabled successfully"
    else
        log_message "WARNING: Failed to disable EEE"
    fi
else
    log_message "WARNING: ethtool not found, skipping EEE disable"
fi

# Disable Wake-on-LAN
if command -v ethtool >/dev/null 2>&1; then
    log_message "Disabling Wake-on-LAN for $REALTEK_INTERFACE"
    ethtool -s "$REALTEK_INTERFACE" wol d 2>/dev/null
    if [ $? -eq 0 ]; then
        log_message "Wake-on-LAN disabled successfully"
    else
        log_message "WARNING: Failed to disable Wake-on-LAN"
    fi
else
    log_message "WARNING: ethtool not found, skipping Wake-on-LAN disable"
fi

# Disable PCIe power wakeup
WAKEUP_FILE="/sys/class/net/$REALTEK_INTERFACE/device/power/wakeup"
if [ -f "$WAKEUP_FILE" ]; then
    log_message "Disabling PCIe power wakeup for $REALTEK_INTERFACE"
    echo "disabled" > "$WAKEUP_FILE" 2>/dev/null
    if [ $? -eq 0 ]; then
        log_message "PCIe power wakeup disabled successfully"
    else
        log_message "WARNING: Failed to disable PCIe power wakeup"
    fi
else
    log_message "WARNING: Power wakeup file not found: $WAKEUP_FILE"
fi

# Set power control to "on" (prevent auto-suspend)
POWER_CONTROL_FILE="/sys/class/net/$REALTEK_INTERFACE/device/power/control"
if [ -f "$POWER_CONTROL_FILE" ]; then
    log_message "Setting power control to 'on' for $REALTEK_INTERFACE"
    echo "on" > "$POWER_CONTROL_FILE" 2>/dev/null
    if [ $? -eq 0 ]; then
        log_message "Power control set to 'on' successfully"
    else
        log_message "WARNING: Failed to set power control to 'on'"
    fi
else
    log_message "WARNING: Power control file not found: $POWER_CONTROL_FILE"
fi

# Bring interface up if it's down
if [ -f "/sys/class/net/$REALTEK_INTERFACE/operstate" ]; then
    current_state=$(cat "/sys/class/net/$REALTEK_INTERFACE/operstate")
    if [ "$current_state" = "down" ]; then
        log_message "Bringing interface $REALTEK_INTERFACE up"
        ip link set "$REALTEK_INTERFACE" up 2>/dev/null
        if [ $? -eq 0 ]; then
            log_message "Interface brought up successfully"
        else
            log_message "WARNING: Failed to bring interface up"
        fi
    else
        log_message "Interface $REALTEK_INTERFACE is already up"
    fi
fi

log_message "Realtek RTL8126 power management fix completed" 
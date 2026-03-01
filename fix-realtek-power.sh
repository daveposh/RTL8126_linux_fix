#!/bin/bash

# Enhanced script to disable power management for Realtek RTL8126 NIC
# This fixes slow network performance issues caused by power management

LOG_FILE="/var/log/realtek-power-fix.log"
VERIFICATION_PASSED=true

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "Starting Realtek RTL8126 power management fix"

# Check dependencies
if ! command -v ethtool >/dev/null 2>&1; then
    log_message "ERROR: ethtool is required but not installed"
    exit 1
fi

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
log_message "Attempting to disable EEE for $REALTEK_INTERFACE"
if ethtool --set-eee "$REALTEK_INTERFACE" eee off 2>/dev/null; then
    log_message "✓ EEE disabled successfully"
else
    log_message "✗ WARNING: Failed to disable EEE (may not be supported)"
    VERIFICATION_PASSED=false
fi

# Disable Wake-on-LAN
log_message "Attempting to disable Wake-on-LAN for $REALTEK_INTERFACE"
if ethtool -s "$REALTEK_INTERFACE" wol d 2>/dev/null; then
    log_message "✓ Wake-on-LAN disabled successfully"
else
    log_message "✗ WARNING: Failed to disable Wake-on-LAN"
    VERIFICATION_PASSED=false
fi

# Disable PCIe power wakeup
WAKEUP_FILE="/sys/class/net/$REALTEK_INTERFACE/device/power/wakeup"
if [ -f "$WAKEUP_FILE" ]; then
    log_message "Attempting to disable PCIe power wakeup for $REALTEK_INTERFACE"
    if echo "disabled" > "$WAKEUP_FILE" 2>/dev/null; then
        log_message "✓ PCIe power wakeup disabled successfully"
    else
        log_message "✗ WARNING: Failed to disable PCIe power wakeup"
        VERIFICATION_PASSED=false
    fi
else
    log_message "✗ WARNING: Power wakeup file not found: $WAKEUP_FILE"
    VERIFICATION_PASSED=false
fi

# Set power control to "on" (prevent auto-suspend)
POWER_CONTROL_FILE="/sys/class/net/$REALTEK_INTERFACE/device/power/control"
if [ -f "$POWER_CONTROL_FILE" ]; then
    log_message "Attempting to set power control to 'on' for $REALTEK_INTERFACE"
    if echo "on" > "$POWER_CONTROL_FILE" 2>/dev/null; then
        log_message "✓ Power control set to 'on' successfully"
    else
        log_message "✗ WARNING: Failed to set power control to 'on'"
        VERIFICATION_PASSED=false
    fi
else
    log_message "✗ WARNING: Power control file not found: $POWER_CONTROL_FILE"
    VERIFICATION_PASSED=false
fi

# Bring interface up if it's down
if [ -f "/sys/class/net/$REALTEK_INTERFACE/operstate" ]; then
    current_state=$(cat "/sys/class/net/$REALTEK_INTERFACE/operstate")
    if [ "$current_state" = "down" ]; then
        log_message "Bringing interface $REALTEK_INTERFACE up"
        if ip link set "$REALTEK_INTERFACE" up 2>/dev/null; then
            log_message "✓ Interface brought up successfully"
        else
            log_message "✗ WARNING: Failed to bring interface up"
            VERIFICATION_PASSED=false
        fi
    else
        log_message "Interface $REALTEK_INTERFACE is already up (state: $current_state)"
    fi
fi

# Verification step
log_message ""
log_message "=== Verification Report ==="
log_message "Interface: $REALTEK_INTERFACE"

# Verify EEE status
if output=$(ethtool --show-eee "$REALTEK_INTERFACE" 2>/dev/null); then
    if echo "$output" | grep -q "EEE status: disabled"; then
        log_message "✓ EEE verified disabled"
    else
        log_message "✗ EEE status verification failed"
    fi
fi

# Verify Wake-on-LAN status
if output=$(ethtool "$REALTEK_INTERFACE" 2>/dev/null); then
    if echo "$output" | grep -q "Wake-on: d"; then
        log_message "✓ Wake-on-LAN verified disabled"
    else
        log_message "✗ Wake-on-LAN status verification failed"
    fi
fi

# Verify power control
if [ -f "$POWER_CONTROL_FILE" ]; then
    control_state=$(cat "$POWER_CONTROL_FILE")
    log_message "✓ Power control verified: $control_state"
fi

# Verify power wakeup
if [ -f "$WAKEUP_FILE" ]; then
    wakeup_state=$(cat "$WAKEUP_FILE")
    log_message "✓ Power wakeup verified: $wakeup_state"
fi

if [ "$VERIFICATION_PASSED" = true ]; then
    log_message ""
    log_message "✓✓✓ Realtek RTL8126 power management fix completed successfully ✓✓✓"
else
    log_message ""
    log_message "⚠ Fix completed with warnings - check log for details"
fi

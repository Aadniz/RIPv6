#!/usr/bin/env bash

# -----
# Name: RIPv6
# Copyright:
#  (c) 2016-2025 Michael Schneider (scip AG)
#  (c) 2025 Aadniz
# Date: 29-03-2025
# Version: 0.3.0
# -----

# -----
# Configurable Variables with defaults
# -----
: "${SLEEP_TIME:=5m}"
: "${MAX_IPS:=5}"

# Required Variables
: "${INTERFACE:?Error: INTERFACE environment variable required}"
: "${NETWORK_ADDR:?Error: NETWORK_ADDR environment variable required}"
: "${GATEWAY_ADDR:?Error: GATEWAY_ADDR environment variable required}"

# -----
# Generate Random Address
# Thx to Vladislav V. Prodan [https://gist.github.com/click0/939739]
# -----
GenerateAddress() {
  array=( 1 2 3 4 5 6 7 8 9 0 a b c d e f )
  a=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
  b=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
  c=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
  d=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
  echo $NETWORK_ADDR:$a:$b:$c:$d
}

# -----
# Initial Setup
# -----
echo "[*] Configuration:"
echo "  Interface: $INTERFACE"
echo "  Network: $NETWORK_ADDR"
echo "  Gateway: $GATEWAY_ADDR"
echo "  Max IPs: $MAX_IPS"
echo "  Sleep Time: $SLEEP_TIME"

# -----
# Gateway Configuration
# -----
if ! ip -6 route show default | grep -q "via $GATEWAY_ADDR dev $INTERFACE"; then
    : "${GATEWAY_ADDR:?Error: GATEWAY_ADDR environment variable required and no existing route found}"
    echo "[*] Setting default route via $GATEWAY_ADDR"
    ip -6 route add default via "$GATEWAY_ADDR" dev "$INTERFACE" || {
        echo "[!] Failed to set default route" >&2
        exit 1
    }
else
    echo "[*] Using existing default route via $GATEWAY_ADDR"
    # Extract gateway from existing route if not set in environment
    if [ -z "$GATEWAY_ADDR" ]; then
        GATEWAY_ADDR=$(ip -6 route show default | awk '/via/ {print $3}')
        echo "[*] Detected gateway: $GATEWAY_ADDR"
    fi
fi

# Cleanup function for trap
cleanup() {
    echo -e "\n[*] Received interrupt signal - cleaning up..."
    echo "[*] Removing all generated IPs"
    for ip in "${current_ips[@]}"; do
        ip -6 addr del "$ip"/64 dev $INTERFACE 2>/dev/null
    done
    exit 0
}

# Set trap for SIGINT (Ctrl+C) and SIGTERM
trap cleanup INT TERM

# Array to store current IPs
declare -a current_ips=()

# -----
# Run IPv6-Address-Loop
# -----
while true
do
  # Generate and add new IP
  new_ip=$(GenerateAddress)
  echo "[+] Added IP: $new_ip"
  ip -6 addr add $new_ip/64 dev $INTERFACE

  # Remove oldest IP if we've reached MAX_IPS
  if [[ ${#current_ips[@]} -ge $MAX_IPS ]]; then
    old_ip=${current_ips[0]}
    echo "[-] Removing IP: $old_ip"
    ip -6 addr del $old_ip/64 dev $INTERFACE
    current_ips=("${current_ips[@]:1}")  # Remove first element
  fi

  # Add new IP to array
  current_ips+=("$new_ip")

  sleep $SLEEP_TIME
done

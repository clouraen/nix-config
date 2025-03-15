#!/usr/bin/env bash
set -euo pipefail

echo "=== NixOS Configuration Bootstrap ==="
echo "This script will guide you through the NixOS installation process."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Function to select from options
select_option() {
  local options=("$@")
  local i=1
  for opt in "${options[@]}"; do
    echo "$i) $opt"
    ((i++))
  done
  
  local selection
  read -p "Enter selection: " selection
  echo "${options[$((selection-1))]}"
}

# Temporary directory for the repository
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "=== Cloning configuration repository ==="
git clone https://github.com/clouraen/nix-config.git "$TEMP_DIR"
cd "$TEMP_DIR"

echo "=== Disk Selection ==="
# Get available disks
mapfile -t DISKS < <(lsblk -dpno NAME,SIZE | grep -v loop | awk '{print $1 " (" $2 ")"}')
if [ ${#DISKS[@]} -eq 0 ]; then
  echo "No disks found. Exiting."
  exit 1
fi

echo "Available disks:"
TARGET_DISK=$(select_option "${DISKS[@]}" | cut -d' ' -f1)

echo "=== Host Configuration ==="
echo "Select host configuration:"
HOST_CONFIG=$(select_option "desktop" "thinkpad-t440p" "macbook-m1")

echo "=== Swap Size ==="
read -p "Enter swap size in GB (default: 8): " SWAP_SIZE
SWAP_SIZE=${SWAP_SIZE:-8}

echo "=== User Configuration ==="
read -p "Enter username: " USERNAME
read -p "Enter full name: " FULLNAME

echo "=== Hostname ==="
read -p "Enter hostname: " HOSTNAME

echo "=== Installation Summary ==="
echo "Target disk: $TARGET_DISK"
echo "Host configuration: $HOST_CONFIG"
echo "Swap size: ${SWAP_SIZE}GB"
echo "Username: $USERNAME"
echo "Full name: $FULLNAME"
echo "Hostname: $HOSTNAME"

read -p "Proceed with installation? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Installation cancelled."
  exit 0
fi

echo "=== Starting NixOS Installation ==="
nix --experimental-features "nix-command flakes" run .#install -- \
  -d "$TARGET_DISK" \
  -h "$HOST_CONFIG" \
  -s "$SWAP_SIZE" \
  -u "$USERNAME" \
  -f "$FULLNAME" \
  -n "$HOSTNAME"

echo "=== Installation Complete ==="
echo "Please reboot your system to boot into NixOS."

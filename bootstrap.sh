#!/usr/bin/env bash
set -euo pipefail

# Function to display usage
usage() {
  echo "Usage: $0 [--interactive] | [-d disk -h host -u username -f fullname -n hostname [-s swap-size]]"
  echo
  echo "Options:"
  echo "  --interactive    Run in interactive mode with guided prompts"
  echo "  -d, --disk       Target disk for installation (e.g., /dev/sda)"
  echo "  -h, --host       Host configuration (desktop, thinkpad-t440p, macbook-m1)"
  echo "  -s, --swap       Swap size in GB (default: 8)"
  echo "  -u, --username   Username for the system"
  echo "  -f, --fullname   Full name for the user (use quotes)"
  echo "  -n, --hostname   Hostname for the system"
  echo
  echo "Examples:"
  echo "  $0 --interactive"
  echo "  $0 -d /dev/sda -h desktop -u john -f \"John Doe\" -n nixos-desktop -s 16"
  exit 1
}

# Initialize variables
INTERACTIVE=0
DISK=""
HOST=""
SWAP_SIZE="8"
USERNAME=""
FULLNAME=""
HOSTNAME=""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Parse command line arguments
if [ "$#" -eq 0 ] || [ "$1" = "--interactive" ]; then
  INTERACTIVE=1
else
  # Not interactive, so parse all required arguments
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -d|--disk)
        if [ "$#" -lt 2 ]; then echo "Missing argument for $1"; usage; fi
        DISK="$2"
        shift 2
        ;;
      -h|--host)
        if [ "$#" -lt 2 ]; then echo "Missing argument for $1"; usage; fi
        HOST="$2"
        shift 2
        ;;
      -s|--swap)
        if [ "$#" -lt 2 ]; then echo "Missing argument for $1"; usage; fi
        SWAP_SIZE="$2"
        shift 2
        ;;
      -u|--username)
        if [ "$#" -lt 2 ]; then echo "Missing argument for $1"; usage; fi
        USERNAME="$2"
        shift 2
        ;;
      -f|--fullname)
        if [ "$#" -lt 2 ]; then echo "Missing argument for $1"; usage; fi
        FULLNAME="$2"
        shift 2
        ;;
      -n|--hostname)
        if [ "$#" -lt 2 ]; then echo "Missing argument for $1"; usage; fi
        HOSTNAME="$2"
        shift 2
        ;;
      --help)
        usage
        ;;
      *)
        echo "Unknown option: $1"
        usage
        ;;
    esac
  done
  
  # Validate required parameters for non-interactive mode
  if [ -z "$DISK" ] || [ -z "$HOST" ] || [ -z "$USERNAME" ] || [ -z "$FULLNAME" ] || [ -z "$HOSTNAME" ]; then
    echo "Missing required parameters."
    usage
  fi
  
  # Validate host configuration
  if [[ ! "$HOST" =~ ^(desktop|thinkpad-t440p|macbook-m1)$ ]]; then
    echo "Invalid host configuration. Supported hosts: desktop, thinkpad-t440p, macbook-m1"
    exit 1
  fi
  
  # Make sure disk exists
  if [ ! -b "$DISK" ]; then
    echo "Disk $DISK does not exist or is not a block device."
    exit 1
  fi
fi

echo "=== NixOS Configuration Bootstrap ==="
echo "This script will guide you through the NixOS installation process."

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

# If interactive mode, prompt for all parameters
if [ "$INTERACTIVE" -eq 1 ]; then
  echo "=== Disk Selection ==="
  # Get available disks
  mapfile -t DISKS < <(lsblk -dpno NAME,SIZE | grep -v loop | awk '{print $1 " (" $2 ")"}')
  if [ ${#DISKS[@]} -eq 0 ]; then
    echo "No disks found. Exiting."
    exit 1
  fi

  echo "Available disks:"
  DISK=$(select_option "${DISKS[@]}" | cut -d' ' -f1)

  echo "=== Host Configuration ==="
  echo "Select host configuration:"
  HOST=$(select_option "desktop" "thinkpad-t440p" "macbook-m1")

  echo "=== Swap Size ==="
  read -p "Enter swap size in GB (default: 8): " SWAP_SIZE_INPUT
  SWAP_SIZE=${SWAP_SIZE_INPUT:-8}

  echo "=== User Configuration ==="
  read -p "Enter username: " USERNAME
  read -p "Enter full name: " FULLNAME

  echo "=== Hostname ==="
  read -p "Enter hostname: " HOSTNAME
fi

echo "=== Installation Summary ==="
echo "Target disk: $DISK"
echo "Host configuration: $HOST"
echo "Swap size: ${SWAP_SIZE}GB"
echo "Username: $USERNAME"
echo "Full name: $FULLNAME"
echo "Hostname: $HOSTNAME"

# If in interactive mode, ask for confirmation
if [ "$INTERACTIVE" -eq 1 ]; then
  read -p "Proceed with installation? (y/N): " CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
  fi
fi

echo "=== Starting NixOS Installation ==="
nix --experimental-features "nix-command flakes" run .#install -- \
  -d "$DISK" \
  -h "$HOST" \
  -s "$SWAP_SIZE" \
  -u "$USERNAME" \
  -f "$FULLNAME" \
  -n "$HOSTNAME"

echo "=== Installation Complete ==="
echo "Please reboot your system to boot into NixOS."

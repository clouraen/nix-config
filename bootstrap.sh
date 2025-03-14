#!/usr/bin/env bash

# Bootstrap script for NixOS configuration
# This script automates the installation process by downloading the configuration
# repository and running the installation script with the provided parameters.

set -euo pipefail

# Default values
DEVICE=""
HOST=""
SWAP_SIZE="8G"
REPO_URL="https://github.com/clouraen/nix-config.git"
REPO_DIR="nix-config"

# Check if running from NixOS installer
if [ ! -f /etc/NIXOS ]; then
  echo "Warning: This script should be run from the NixOS installer environment."
  read -p "Continue anyway? (y/N) " confirm
  if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    exit 1
  fi
fi

# Function to list available devices
list_devices() {
  echo "Available devices:"
  lsblk -p -o NAME,SIZE,TYPE,MOUNTPOINTS | grep disk
  echo ""
}

# Function to prompt for device
prompt_device() {
  list_devices
  while [ -z "$DEVICE" ]; do
    read -p "Enter the target device for installation (e.g., /dev/sda): " input_device
    if [ -b "$input_device" ]; then
      DEVICE=$input_device
    else
      echo "Invalid device. Please select a valid block device."
      list_devices
    fi
  done
}

# Function to prompt for host
prompt_host() {
  echo "Supported hosts:"
  echo "1) desktop (i7 3370 + GTX 4060)"
  echo "2) thinkpad-t440p"
  echo "3) macbook-m1"
  echo ""
  
  while [ -z "$HOST" ]; do
    read -p "Select host configuration [1-3]: " host_selection
    case $host_selection in
      1) HOST="desktop" ;;
      2) HOST="thinkpad-t440p" ;;
      3) HOST="macbook-m1" ;;
      *) echo "Invalid selection. Please choose a number between 1 and 3." ;;
    esac
  done
}

# Function to prompt for swap size
prompt_swap_size() {
  read -p "Enter swap size (default: 8G): " input_swap
  if [ -n "$input_swap" ]; then
    SWAP_SIZE=$input_swap
  fi
}

# Welcome message
echo "====== NixOS Installation Bootstrap ======"
echo "This interactive script will guide you through the NixOS installation process."
echo "========================================"

# Collect installation parameters
prompt_device
prompt_host
prompt_swap_size

# Confirm installation parameters
echo ""
echo "Installation Parameters:"
echo "Device: $DEVICE"
echo "Host: $HOST"
echo "Swap Size: $SWAP_SIZE"
echo ""

read -p "Proceed with installation? (y/N) " confirm
if [[ ! "$confirm" =~ ^[yY]$ ]]; then
  echo "Installation cancelled."
  exit 0
fi

# Create temporary directory and navigate to it
TEMP_DIR=$(mktemp -d)
echo "Working in temporary directory: $TEMP_DIR"
cd "$TEMP_DIR"

# Clone the repository
echo "Cloning the configuration repository..."
git clone "$REPO_URL" "$REPO_DIR" || { echo "Failed to clone repository"; exit 1; }
cd "$REPO_DIR"

# Run the installation script
echo "Running the installation script..."
nix --experimental-features "nix-command flakes" run .#install -- -d "$DEVICE" -h "$HOST" -s "$SWAP_SIZE"

echo "Installation process completed!"

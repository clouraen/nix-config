#!/bin/bash

set -e

# Default values
DISK=""
HOSTNAME=""
SWAP_SIZE="8G"

print_usage() {
    echo "Usage: $0 -d <disk> -h <hostname> [-s <swap_size>]"
    echo "Example: $0 -d /dev/nvme0n1 -h desktop -s 16G"
}

while getopts "d:h:s:" opt; do
    case $opt in
        d) DISK="$OPTARG";;
        h) HOSTNAME="$OPTARG";;
        s) SWAP_SIZE="$OPTARG";;
        ?) print_usage; exit 1;;
    esac
done

if [ -z "$DISK" ] || [ -z "$HOSTNAME" ]; then
    print_usage
    exit 1
fi

# Skip automatic partitioning for MacBook
if [ "$HOSTNAME" = "macbook-m1" ]; then
    echo "MacBook M1 detected. Manual partitioning required."
    exit 1
fi

echo "WARNING: This will erase all data on $DISK"
read -p "Are you sure you want to continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Wipe disk completely first
wipefs -a $DISK
dd if=/dev/zero of=$DISK bs=4M count=10

# Create partitions
parted $DISK -- mklabel gpt
parted $DISK -- mkpart ESP fat32 1MiB 512MiB
parted $DISK -- set 1 esp on
parted $DISK -- mkpart primary 512MiB -${SWAP_SIZE}
parted $DISK -- mkpart primary linux-swap -${SWAP_SIZE} 100%

# Format partitions
mkfs.fat -F 32 -n BOOT "${DISK}1"
mkfs.ext4 -L NIXOS "${DISK}2"
mkswap -L SWAP "${DISK}3"

# Mount partitions
mount /dev/disk/by-label/NIXOS /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/BOOT /mnt/boot
swapon /dev/disk/by-label/SWAP

# Clone configuration
git clone https://github.com/your-username/nix-config.git /mnt/etc/nixos

# Generate hardware config
nixos-generate-config --root /mnt

# Install NixOS
nixos-install --flake /mnt/etc/nixos#$HOSTNAME

echo "Installation complete! You can reboot now."

#!/usr/bin/env bash
set -euo pipefail

DISK=""
HOST=""
SWAP_SIZE="8"
USERNAME=""
FULLNAME=""
HOSTNAME=""
PASSWORD=""

# Parse arguments
while getopts "d:h:s:u:f:n:p:" opt; do
  case $opt in
    d) DISK="$OPTARG" ;;
    h) HOST="$OPTARG" ;;
    s) SWAP_SIZE="$OPTARG" ;;
    u) USERNAME="$OPTARG" ;;
    f) FULLNAME="$OPTARG" ;;
    n) HOSTNAME="$OPTARG" ;;
    p) PASSWORD="$OPTARG" ;;
    *) echo "Usage: $0 -d <disk> -h <host> [-s <swap-size>] -u <username> -f \"<fullname>\" -n <hostname> [-p <password>]" && exit 1 ;;
  esac
done

# Validate required parameters
if [ -z "$DISK" ] || [ -z "$HOST" ] || [ -z "$USERNAME" ] || [ -z "$FULLNAME" ] || [ -z "$HOSTNAME" ]; then
  echo "Missing required parameters. Usage:"
  echo "$0 -d <disk> -h <host> [-s <swap-size>] -u <username> -f \"<fullname>\" -n <hostname> [-p <password>]"
  exit 1
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

echo "=== NixOS Installation ==="
echo "Target disk: $DISK"
echo "Host configuration: $HOST"
echo "Swap size: ${SWAP_SIZE}GB"
echo "Username: $USERNAME"
echo "Full name: $FULLNAME"
echo "Hostname: $HOSTNAME"

echo "=== Partitioning Disk ==="
# Wipe disk
wipefs -a "$DISK"

# Create partition layout
parted "$DISK" -- mklabel gpt
parted "$DISK" -- mkpart ESP fat32 1MiB 512MiB
parted "$DISK" -- set 1 esp on
parted "$DISK" -- mkpart primary 512MiB -"${SWAP_SIZE}"GiB
parted "$DISK" -- mkpart primary linux-swap -"${SWAP_SIZE}"GiB 100%

# Format partitions
EFI_PART="${DISK}1"
ROOT_PART="${DISK}2"
SWAP_PART="${DISK}3"

mkfs.fat -F32 "$EFI_PART"
mkfs.ext4 -L nixos "$ROOT_PART"
mkswap -L swap "$SWAP_PART"
swapon "$SWAP_PART"

# Mount partitions
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot/efi
mount "$EFI_PART" /mnt/boot/efi

echo "=== Generating NixOS Configuration ==="
# Hash the password if provided
if [ -n "$PASSWORD" ]; then
  HASHED_PASSWORD=$(nix-shell -p mkpasswd --run "mkpasswd -m sha-512 '$PASSWORD'")
else
  HASHED_PASSWORD='!'  # Locked password
fi

# Generate hardware configuration
nixos-generate-config --root /mnt

# Clone repository to the new system
mkdir -p /mnt/etc/nixos
git clone https://github.com/clouraen/nix-config.git /mnt/etc/nixos

# Create host-specific configuration
mkdir -p "/mnt/etc/nixos/hosts/$HOSTNAME"
cat > "/mnt/etc/nixos/hosts/$HOSTNAME/default.nix" <<EOF
{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base
    ../../modules/desktop
    ../../modules/users
  ];

  # Host-specific settings
  networking.hostName = "$HOSTNAME";
  users.users.$USERNAME = {
    isNormalUser = true;
    description = "$FULLNAME";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    hashedPassword = "${HASHED_PASSWORD}";
  };
}
EOF

# Copy the generated hardware configuration
cp /mnt/etc/nixos/hardware-configuration.nix "/mnt/etc/nixos/hosts/$HOSTNAME/"

echo "=== Installing NixOS ==="
# Install NixOS
nixos-install --no-root-passwd --flake "/mnt/etc/nixos#$HOST"

echo "=== Installation Complete ==="
echo "NixOS has been installed successfully."
echo "After rebooting, remember to set a password for your user with 'passwd'."
echo "You can update your system with: sudo nixos-rebuild switch --flake /etc/nixos"
echo "Reboot with: systemctl reboot"

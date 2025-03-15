#!/usr/bin/env bash
set -euo pipefail

# Function to select host configuration
select_host() {
  local hosts=(desktop thinkpad-t440p macbook-m1)
  echo "=== Host Configuration ==="
  for i in "${!hosts[@]}"; do
    echo "[$i] ${hosts[$i]}"
  done
  
  local selection
  while true; do
    read -rp "Enter selection: " selection
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -lt "${#hosts[@]}" ]; then
      echo "Selected host: ${hosts[$selection]}"
      echo
      echo "=== Host Selected ==="
      echo "Host: ${hosts[$selection]}"
      echo
      return "$selection"
    fi
    echo "Invalid selection. Please try again."
  done
}

# Function to select disk
select_disk() {
  echo "=== Disk Selection ==="
  local i=0
  local disks=()
  
  while read -r disk size name; do
    disks+=("$disk")
    echo "[$i] $disk   ${size}B $name"
    ((i++))
  done < <(lsblk -dpno NAME,SIZE,MODEL | grep -E '^/dev/(sd|nvme|vd)')
  
  local selection
  while true; do
    read -rp "Enter selection: " selection
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -lt "${#disks[@]}" ]; then
      echo "Selected disk: ${disks[$selection]}"
      echo
      echo "=== Disk Selected ==="
      echo "Disk: ${disks[$selection]}"
      echo
      DISK="${disks[$selection]}"
      break
    fi
    echo "Invalid selection. Please try again."
  done
}

# Initialize variables
DISK=""
HOST=""
SWAP_SIZE="8"
USERNAME=""
FULLNAME=""
HOSTNAME=""
PASSWORD=""

# Get selections first
host_index=$(select_host)
HOST=$(echo -e "desktop\nthinkpad-t440p\nmacbook-m1" | sed -n "$((host_index+1))p")
select_disk

# Parse remaining arguments
while getopts "s:u:f:n:p:" opt; do
  case $opt in
    s) SWAP_SIZE="$OPTARG" ;;
    u) USERNAME="$OPTARG" ;;
    f) FULLNAME="$OPTARG" ;;
    n) HOSTNAME="$OPTARG" ;;
    p) PASSWORD="$OPTARG" ;;
    *) echo "Usage: $0 [-s <swap-size>] -u <username> -f \"<fullname>\" -n <hostname> [-p <password>]" && exit 1 ;;
  esac
done

# Validate required parameters
if [ -z "$USERNAME" ] || [ -z "$FULLNAME" ] || [ -z "$HOSTNAME" ]; then
  echo "Missing required parameters. Usage:"
  echo "$0 [-s <swap-size>] -u <username> -f \"<fullname>\" -n <hostname> [-p <password>]"
  exit 1
fi

echo

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

echo "=== Preparing Disk ==="
# Check for and stop MDADM arrays using the disk
if command -v mdadm >/dev/null 2>&1; then
  echo "Checking for MDADM RAID arrays..."
  if [ -f /proc/mdstat ]; then
    while read -r array; do
      if mdadm --detail "/dev/$array" 2>/dev/null | grep -q "$DISK"; then
        echo "Stopping RAID array /dev/$array..."
        mdadm --stop "/dev/$array" || true
      fi
    done < <(awk '/^md/ {print $1}' /proc/mdstat)
  fi
fi

# Check for and remove LVM volumes
if command -v lvs >/dev/null 2>&1; then
  echo "Checking for LVM volumes..."
  for vg in $(vgs --noheadings -o vg_name 2>/dev/null); do
    for lv in $(lvs --noheadings -o lv_name "$vg" 2>/dev/null); do
      if lvs --noheadings -o devices "$vg/$lv" 2>/dev/null | grep -q "$DISK"; then
        echo "Removing LVM volume $vg/$lv..."
        lvremove -f "$vg/$lv" || true
      fi
    done
  done
fi

# Unmount any partitions from the target disk
for mount in $(mount | grep "^$DISK" | awk '{ print $1 }'); do
  echo "Unmounting $mount..."
  umount -f "$mount" || true
done

# Disable any swap partitions on the target disk
for swap in $(swapon --show=NAME | grep "^$DISK"); do
  echo "Disabling swap on $swap..."
  swapoff "$swap" || true
done

echo "=== Partitioning Disk ==="
# Ensure disk is not busy and wipe it
sync
sleep 1

# Wait for udev to settle
if command -v udevadm >/dev/null 2>&1; then
  echo "Waiting for udev to settle..."
  udevadm settle || true
fi

echo "Wiping disk $DISK..."
wipefs -af "$DISK"

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

echo "=== Setting up NixOS Configuration ==="
# Hash the password if provided
if [ -n "$PASSWORD" ]; then
  HASHED_PASSWORD=$(nix-shell -p mkpasswd --run "mkpasswd -m sha-512 '$PASSWORD'")
else
  HASHED_PASSWORD='!'  # Locked password
fi

# Clean up any existing nixos configuration
rm -rf /mnt/etc/nixos

# Clone repository to the new system
mkdir -p /mnt/etc/nixos
git clone https://github.com/clouraen/nix-config.git /mnt/etc/nixos

# Generate hardware configuration and save it
TEMP_DIR=$(mktemp -d)
nixos-generate-config --root /mnt --dir "$TEMP_DIR"
mv "$TEMP_DIR/hardware-configuration.nix" /mnt/etc/nixos/
rm -rf "$TEMP_DIR"

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

# Move the generated hardware configuration to host directory
mv /mnt/etc/nixos/hardware-configuration.nix "/mnt/etc/nixos/hosts/$HOSTNAME/"

echo "=== Installing NixOS ==="
# Install NixOS
nixos-install --no-root-passwd --flake "/mnt/etc/nixos#$HOST"

echo "=== Installation Complete ==="
echo "NixOS has been installed successfully."
echo "After rebooting, remember to set a password for your user with 'passwd'."
echo "You can update your system with: sudo nixos-rebuild switch --flake /etc/nixos"
echo "Reboot with: systemctl reboot"

#!/usr/bin/env bash
set -euo pipefail

echo "=== NixOS Configuration Bootstrap ==="
echo "This script will guide you through the NixOS installation process."

# Configuration directory
CONFIG_DIR="/home/cleiton-moura/Downloads/nix-config"

# Default values
DISK=""
SELECTED_HOST=""
SWAP_SIZE="8G"
USERNAME=""
FULLNAME=""
HOSTNAME=""
INTERACTIVE=true

# Parse command line arguments
usage() {
    echo "Usage: $0 [-d <disk>] [-h <host>] [-s <swap-size>] [-u <username>] [-f \"<fullname>\"] [-n <hostname>]"
    echo "  -d <disk>       Target disk for installation (e.g., /dev/sda)"
    echo "  -h <host>       Host configuration to use"
    echo "  -s <swap-size>  Swap size (default: 8G)"
    echo "  -u <username>   Username for the new user"
    echo "  -f <fullname>   Full name for the new user"
    echo "  -n <hostname>   System hostname"
    exit 1
}

while getopts "d:h:s:u:f:n:" opt; do
    case ${opt} in
        d) DISK="$OPTARG"; INTERACTIVE=false ;;
        h) SELECTED_HOST="$OPTARG"; INTERACTIVE=false ;;
        s) SWAP_SIZE="$OPTARG" ;;
        u) USERNAME="$OPTARG" ;;
        f) FULLNAME="$OPTARG" ;;
        n) HOSTNAME="$OPTARG" ;;
        \?) usage ;;
    esac
done

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root!"
    exit 1
fi

# Function to clone the repository if it doesn't exist
setup_repo() {
    if [ ! -d "$CONFIG_DIR" ]; then
        echo "=== Cloning configuration repository ==="
        git clone https://github.com/clouraen/nix-config "$CONFIG_DIR"
    fi
}

# Disk selection
select_disk() {
    if [ -n "$DISK" ]; then
        echo "Target disk: $DISK"
        return
    fi
    
    echo "=== Disk Selection ==="
    echo "Available disks:"
    
    # List available disks
    mapfile -t disks < <(lsblk -dpno NAME,SIZE,MODEL | grep -E '^/dev/(nvme|sd|vd)')
    
    for i in "${!disks[@]}"; do
        echo "[$i] ${disks[$i]}"
    done
    
    read -rp "Enter selection: " selection
    DISK=$(echo "${disks[$selection]}" | awk '{print $1}')
    echo "Selected disk: $DISK"
}

# Host configuration selection function
select_host() {
    if [ -n "$SELECTED_HOST" ]; then
        echo "Selected host: $SELECTED_HOST"
        echo "$SELECTED_HOST" > "$(dirname "$0")/../hostname"
        echo "Host configuration set to $SELECTED_HOST"
        return
    fi
    
    echo ""
    echo "=== Host Configuration Selection ==="
    echo ""

    # Find available host configurations
    HOSTS_DIR="$(dirname "$0")/../hosts"
    mapfile -t HOSTS < <(find "$HOSTS_DIR" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | sort)

    if [ ${#HOSTS[@]} -eq 0 ]; then
        echo "Error: No host configurations found in $HOSTS_DIR"
        exit 1
    fi

    # Display menu
    echo "Available host configurations:"
    echo "-----------------------------"
    for i in "${!HOSTS[@]}"; do
        echo "[$((i+1))] ${HOSTS[$i]}"
    done
    echo "-----------------------------"

    # Get user selection
    local selection
    while true; do
        read -rp "Select host configuration [1-${#HOSTS[@]}]: " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#HOSTS[@]}" ]; then
            SELECTED_HOST="${HOSTS[$((selection-1))]}"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done

    echo "Selected host: $SELECTED_HOST"
    
    # Create hostname file
    echo "$SELECTED_HOST" > "$(dirname "$0")/../hostname"
    echo "Host configuration set to $SELECTED_HOST"
}

# Configure user settings
configure_user() {
    if [ -n "$USERNAME" ] && [ -n "$FULLNAME" ] && [ -n "$HOSTNAME" ]; then
        echo "Username: $USERNAME"
        echo "Full name: $FULLNAME"
        echo "Hostname: $HOSTNAME"
        return
    fi
    
    echo ""
    echo "=== User Configuration ==="
    echo ""
    
    if [ -z "$USERNAME" ]; then
        read -rp "Enter username: " USERNAME
    fi
    
    if [ -z "$FULLNAME" ]; then
        read -rp "Enter full name: " FULLNAME
    fi
    
    if [ -z "$HOSTNAME" ]; then
        read -rp "Enter hostname: " HOSTNAME
    fi
}

# Apply NixOS configuration
apply_config() {
    echo "=== Applying NixOS Configuration ==="
    echo "Building and switching to configuration for $SELECTED_HOST..."
    
    # Configure sops-nix if not already configured
    if [ ! -f "$CONFIG_DIR/keys.txt" ]; then
        echo "Configuring keys for sops-nix..."
        mkdir -p "$CONFIG_DIR"
        nix-shell -p sops -p age --run "age-keygen -o $CONFIG_DIR/keys.txt"
        chmod 600 "$CONFIG_DIR/keys.txt"
    fi
    
    # Apply configuration using the exact host name in flake.nix
    echo "Executing: nixos-rebuild switch --flake $CONFIG_DIR#$SELECTED_HOST"
    nixos-rebuild switch --flake "$CONFIG_DIR#$SELECTED_HOST"
}

# Display installation summary
show_summary() {
    echo ""
    echo "=== Installation Summary ==="
    echo "Target disk: $DISK"
    echo "Host configuration: $SELECTED_HOST"
    echo "Swap size: $SWAP_SIZE"
    echo "Username: $USERNAME"
    echo "Full name: $FULLNAME"
    echo "Hostname: $HOSTNAME"
    echo ""
    
    if [ "$INTERACTIVE" = true ]; then
        read -rp "Proceed with installation? [Y/n] " confirm
        if [[ "$confirm" =~ ^[Nn] ]]; then
            echo "Installation aborted."
            exit 0
        fi
    fi
    
    echo "=== Starting NixOS Installation ==="
}

# Execute the script
setup_repo
select_disk
select_host
configure_user
show_summary
apply_config

echo "=== Bootstrap completed successfully ==="
echo "Your NixOS system has been configured as $SELECTED_HOST"

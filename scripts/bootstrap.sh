#!/usr/bin/env bash
set -euo pipefail

echo "=== NixOS Configuration Bootstrap ==="
echo "This script will guide you through the NixOS installation process."

# Configuration directory
CONFIG_DIR="/home/cleiton-moura/Downloads/nix-config"
# Hosts directory
HOSTS_DIR="$CONFIG_DIR/hosts"

# Function to install required tools
install_tools() {
    echo "Installing required tools..."
    nix-shell -p dmidecode laptop-detect pciutils usbutils util-linux lshw --run "true" || true

    # Ensure access to system information
    if [ -d "/sys/class/dmi/id" ]; then
        chmod -f a+r /sys/class/dmi/id/* 2>/dev/null || true
    fi
    if [ -d "/sys/class/power_supply" ]; then
        chmod -f a+r /sys/class/power_supply/* 2>/dev/null || true
    fi
}

# Function to probe hardware using nixos-hardware methods
probe_hardware() {
    local hw_info=""
    
    # Get detailed hardware information
    hw_info+="=== System Information ===\n"
    hw_info+="$(dmidecode -t system 2>/dev/null || true)\n\n"
    
    hw_info+="=== CPU Information ===\n"
    hw_info+="$(lscpu 2>/dev/null || true)\n\n"
    
    hw_info+="=== PCI Devices ===\n"
    hw_info+="$(lspci 2>/dev/null || true)\n\n"
    
    hw_info+="=== USB Devices ===\n"
    hw_info+="$(lsusb 2>/dev/null || true)\n\n"
    
    hw_info+="=== Hardware Overview ===\n"
    hw_info+="$(lshw -short 2>/dev/null || true)\n"
    
    echo -e "$hw_info" > "$CONFIG_DIR/hardware-probe.txt"
}

# Function to detect system hardware
detect_hardware() {
    # First run hardware probe
    probe_hardware
    local detected_host=""
    local system_info
    local product_name
    local sys_vendor
    local chassis_type
    
    # Get system information using more reliable methods
    if [ -d "/sys/class/dmi/id/" ]; then
        sys_vendor=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "")
        product_name=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")
        chassis_type=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || echo "")
    else
        system_info=$(dmidecode -t system 2>/dev/null || echo "")
        sys_vendor=$(echo "$system_info" | grep "Manufacturer:" | cut -d: -f2- | xargs)
        product_name=$(echo "$system_info" | grep "Product Name:" | cut -d: -f2- | xargs)
        chassis_info=$(dmidecode -t chassis 2>/dev/null || echo "")
        chassis_type=$(echo "$chassis_info" | grep "Type:" | cut -d: -f2- | xargs)
    fi
    
    # Enhanced hardware detection logic
    if grep -q "Apple" /sys/firmware/devicetree/base/compatible 2>/dev/null || \
       [[ "$sys_vendor" == *"Apple"* ]]; then
        if grep -q "M1\|M2" /proc/cpuinfo 2>/dev/null || \
           [[ "$product_name" == *"MacBook"* ]]; then
            detected_host="macbook-m1"
        fi
    elif [[ "$sys_vendor" == *"LENOVO"* ]] || [[ "$sys_vendor" == *"Lenovo"* ]]; then
        if [[ "$product_name" == *"ThinkPad T440p"* ]]; then
            detected_host="thinkpad-t440p"
        fi
    fi
    
    # If no specific model detected, check if it's a laptop
    if [ -z "$detected_host" ]; then
        if [[ "$chassis_type" =~ ^(8|9|10|14)$ ]] || \  # DMI chassis types for laptops/notebooks
           [ -d "/sys/class/power_supply" ] && ls /sys/class/power_supply/BAT* >/dev/null 2>&1 || \
           laptop-detect 2>/dev/null; then
            detected_host="laptop"
        else
            detected_host="desktop"
        fi
    fi
    
    echo "$detected_host"
}

# Function to select host configuration
select_host() {
    echo "=== Host Configuration ==="
    
    # Get list of host configurations
    mapfile -t hosts < <(find "$HOSTS_DIR" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | sort)
    
    if [ ${#hosts[@]} -eq 0 ]; then
        echo "Error: No host configurations found in $HOSTS_DIR"
        exit 1
    fi

    # Try to detect hardware
    local detected_host
    detected_host=$(detect_hardware)
    local detected_index=-1
    
    # Find index of detected host
    for i in "${!hosts[@]}"; do
        if [ "${hosts[$i]}" = "$detected_host" ]; then
            detected_index=$i
            break
        fi
    done
    
    # Display menu with detected host highlighted
    for i in "${!hosts[@]}"; do
        if [ "$i" = "$detected_index" ]; then
            echo "[$i] ${hosts[$i]} (Detected)"
        else
            echo "[$i] ${hosts[$i]}"
        fi
    done
    echo
    
    # Get user selection, defaulting to detected host
    local selection
    if [ "$detected_index" -ge 0 ]; then
        read -rp "Enter selection [default: $detected_index]: " selection
        selection=${selection:-$detected_index}
    else
        read -rp "Enter selection: " selection
    fi
    
    while true; do
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -lt "${#hosts[@]}" ]; then
            SELECTED_HOST="${hosts[$selection]}"
            echo "Selected host: $SELECTED_HOST"
            echo
            echo "=== Host Selected ==="
            echo "Host: $SELECTED_HOST"
            echo
            # Create hostname file
            echo "$SELECTED_HOST" > "$CONFIG_DIR/hostname"
            break
        fi
        echo "Invalid selection. Please try again."
        read -rp "Enter selection: " selection
    done
}

# Default values
DISK=""
SELECTED_HOST=""
SWAP_SIZE="8G"
USERNAME=""
FULLNAME=""
HOSTNAME=""
PASSWORD=""
INTERACTIVE=true

# Parse command line arguments
usage() {
    echo "Usage: $0 [-d <disk>] [-s <swap-size>] [-u <username>] [-f \"<fullname>\"] [-n <hostname>] [-p <password>]"
    echo "  -d <disk>       Target disk for installation (e.g., /dev/sda)"
    echo "  -s <swap-size>  Swap size (default: 8G)"
    echo "  -u <username>   Username for the new user"
    echo "  -f <fullname>   Full name for the new user"
    echo "  -n <hostname>   System hostname"
    echo "  -p <password>   User password (optional)"
    exit 1
}

while getopts "d:s:u:f:n:p:" opt; do
    case ${opt} in
        d) DISK="$OPTARG"; INTERACTIVE=false ;;
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


# Configure user settings
configure_user() {
    if [ -z "$USERNAME" ] || [ -z "$FULLNAME" ] || [ -z "$HOSTNAME" ]; then
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
    fi

    if [ -z "$PASSWORD" ]; then
        echo ""
        echo "=== Password Configuration ==="
        echo ""
        while true; do
            read -rsp "Enter password: " PASSWORD
            echo
            read -rsp "Confirm password: " password2
            echo
            if [ "$PASSWORD" = "$password2" ]; then
                break
            else
                echo "Passwords do not match. Please try again."
                echo
            fi
        done
    fi

    echo ""
    echo "=== User Settings ==="
    echo "Username: $USERNAME"
    echo "Full name: $FULLNAME"
    echo "Hostname: $HOSTNAME"
    echo "Password: [hidden]"
    echo ""
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
    
    # Hash the password if provided
    local password_args=""
    if [ -n "$PASSWORD" ]; then
        HASHED_PASSWORD=$(nix-shell -p mkpasswd --run "mkpasswd -m sha-512 '$PASSWORD'")
        password_args="--argstr hashedPassword '$HASHED_PASSWORD'"
    fi
    
    # Apply configuration using the exact host name in flake.nix
    echo "Executing: nixos-rebuild switch --flake $CONFIG_DIR#$SELECTED_HOST $password_args"
    # shellcheck disable=SC2086
    nixos-rebuild switch --flake "$CONFIG_DIR#$SELECTED_HOST" $password_args
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
install_tools
select_disk
select_host
configure_user
show_summary
apply_config

echo "=== Bootstrap completed successfully ==="
echo "Your NixOS system has been configured as $SELECTED_HOST"

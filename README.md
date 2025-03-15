# NixOS Configuration

This repository contains NixOS configurations for various machines using the Nix Flakes system.

## Quick Start

To install NixOS using this configuration, boot into a NixOS live environment.

### Installation

To install NixOS using this configuration:

```bash
# Download and run the bootstrap script
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/clouraen/nix-config/master/bootstrap.sh)" -- \
  -u [username] \
  -f "[full name]" \
  -n [hostname] \
  [-s swap-size]
```

For example:

```bash
# Example with specific values
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/clouraen/nix-config/master/bootstrap.sh)" -- \
  -u john \
  -f "John Doe" \
  -n my-nixos \
  -s 8
```

### Manual Method

If you prefer to download the script first:

```bash
# Download the bootstrap script
curl -LO https://raw.githubusercontent.com/clouraen/nix-config/master/bootstrap.sh

# Make it executable
chmod +x bootstrap.sh

# Run the script
sudo ./bootstrap.sh -u [username] -f "[full name]" -n [hostname] [-s swap-size]
```

## Required Parameters

The installation script requires:

- `-u <username>`: Username for your account
- `-f "<fullname>"`: Your full name (in quotes)
- `-n <hostname>`: Hostname for your machine
- `-s <swap-size>`: Swap partition size in GB (optional, default is 8)

Note: Disk and host selection are handled through interactive menus during installation.

## Installation Process

The installation process guides you through:

1. **Host Configuration** - Choose from available host configurations:
   ```
   === Host Configuration ===
   [0] desktop
   [1] thinkpad-t440p
   [2] macbook-m1
   ```

2. **Disk Selection** - Select the installation target disk:
   ```
   === Disk Selection ===
   [0] /dev/sda   111.8G KINGSTON SV300S37A120G
   [1] /dev/sdb    14.5G USB DISK 2.0
   ```

3. **System Configuration** - The script uses the provided parameters to:
   - Configure user account (username and full name)
   - Set system hostname
   - Create swap partition (with specified or default size)
   - Install and configure NixOS

## Supported Host Configurations

Currently, this configuration supports:

- **desktop** - Desktop PC with i7 3370 + GTX 4060
- **thinkpad-t440p** - Lenovo ThinkPad T440p laptop
- **macbook-m1** - Apple MacBook with M1 processor

## Manual Installation

To install manually:

1. Clone this repository
2. Run the install script directly:

```bash
# Clone the repository
git clone https://github.com/clouraen/nix-config.git
cd nix-config

# Run the installation
nix --experimental-features "nix-command flakes" run .#install -- \
  -u [username] \
  -f "[full name]" \
  -n [hostname] \
  [-s swap-size]
```

## Post-Installation

After installation, the system will be set up according to the selected host configuration. You may need to:

1. Set a password for your user
2. Configure WiFi (if applicable)
3. Update the system with `sudo nixos-rebuild switch --flake .`

## Customization

To customize your configuration:

1. Fork this repository
2. Modify the files in the `hosts/` and `modules/` directories
3. Add your changes to the flake.nix file

## License

This project is licensed under the MIT License - see the LICENSE file for details.

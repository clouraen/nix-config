# NixOS Configuration

This repository contains NixOS configurations for various machines using the Nix Flakes system.

## Quick Start

To install NixOS using this configuration, boot into a NixOS live environment and run:

```bash
# Simple one-liner with sudo
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/clouraen/nix-config/master/bootstrap.sh)"
```

Or if you prefer step by step:

```bash
# Download the bootstrap script
curl -LO https://raw.githubusercontent.com/clouraen/nix-config/master/bootstrap.sh

# Make it executable
chmod +x bootstrap.sh

# Run the bootstrap script
sudo ./bootstrap.sh
```

## Installation Process

The bootstrap script guides you through an interactive installation process:

1. **Select target device** - Choose the disk where NixOS will be installed
2. **Select host configuration** - Choose from pre-defined host configurations
3. **Set swap size** - Specify the swap partition size (default is 8GB)
4. **Confirm and install** - Review settings before proceeding with installation

## Supported Host Configurations

Currently, this configuration supports:

- **desktop** - Desktop PC with i7 3370 + GTX 4060
- **thinkpad-t440p** - Lenovo ThinkPad T440p laptop
- **macbook-m1** - Apple MacBook with M1 processor

## Manual Installation

If you prefer to install manually:

1. Clone this repository
2. Run the install script directly:

```bash
# Clone the repository
git clone https://github.com/clouraen/nix-config.git
cd nix-config

# Run the installation with custom parameters
nix --experimental-features "nix-command flakes" run .#install -- -d /dev/sdX -h [host] -s [swap-size]
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

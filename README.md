# NixOS Configuration

Customized NixOS system with support for multiple hosts and automated installation.

## Supported Hosts

- Desktop (i7 3370 + GTX 4060)
- ThinkPad T440p
- MacBook M1

## One-line Installation

Run this command directly in the NixOS installer to start the interactive installation:

```bash
# Interactive installation with assistant:
curl -sL https://raw.githubusercontent.com/clouraen/nix-config/refs/heads/master/bootstrap.sh | bash

# The script will:
# 1. List available devices for you to choose
# 2. Present host options (desktop, thinkpad-t440p, macbook-m1)
# 3. Allow you to set the swap size
# 4. Confirm your choices before proceeding
```

## Manual Installation

1. Download the NixOS installer
2. Boot into the installer
3. Clone this repository:
```bash
git clone https://github.com/clouraen/nix-config.git
cd nix-config
```

4. Run the installation script:
```bash
# For Desktop:
nix run .#install -- -d /dev/sda -h desktop -s 16G

# For ThinkPad T440p:
nix run .#install -- -d /dev/nvme0n1 -h thinkpad-t440p -s 8G

# For MacBook M1 (requires manual partitioning):
# First do the manual partitioning and then:
nix run .#install -- -d /dev/nvme0n1 -h macbook-m1 -s 8G
```

## Configurations

### Default User
- Username: huggyturd
- Initial password: nixos
- Passwordless sudo enabled

### Desktop Environment
- Hyprland (Wayland)
- Configuration based on end-4/dots-hyprland

### Common Packages
- Google Chrome
- Vim
- Git
- Terminal: kitty
- Bar: waybar
- Notifications: dunst
- Menu: wofi/rofi

### Host-Specific

#### Desktop
- Optimized NVIDIA drivers
- OpenGL/Vulkan support
- Intel CPU performance

#### ThinkPad T440p
- TLP for battery management
- ThinkFan
- Configured trackpoint

#### MacBook M1
- Optimized Asahi Linux
- Specific firmware
- Power management

## Maintenance

To update the system:
```bash
sudo nixos-rebuild switch
```

To update with changes in the flake:
```bash
sudo nixos-rebuild switch --flake .#hostname
```

## Project Structure
````
.
├── common/           # Shared configurations
├── hosts/           # Host-specific configurations
├── modules/         # Custom modules
└── scripts/         # Installation scripts

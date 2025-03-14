{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.disk;
  hostname = config.networking.hostName;
in {
  options.mySystem.disk = with lib; {
    device = mkOption {
      type = types.str;
      example = "/dev/sda";
      description = "The disk device to use for installation";
    };
    
    swapSize = mkOption {
      type = types.str;
      default = "8G";
      description = "Size of swap partition";
    };
  };

  config = lib.mkIf (hostname != "macbook-m1" && cfg.device != "") {
    system.activationScripts.baseDiskSetup = ''
      if [ ! -e /etc/NIXOS ]; then
        # Wipe disk completely first
        wipefs -a ${cfg.device}
        dd if=/dev/zero of=${cfg.device} bs=4M count=10

        # Continue with partitioning
        parted ${cfg.device} -- mklabel gpt
        parted ${cfg.device} -- mkpart ESP fat32 1MiB 512MiB
        parted ${cfg.device} -- set 1 esp on
        parted ${cfg.device} -- mkpart primary 512MiB -${cfg.swapSize}
        parted ${cfg.device} -- mkpart primary linux-swap -${cfg.swapSize} 100%

        mkfs.fat -F 32 -n BOOT "${cfg.device}1"
        mkfs.ext4 -L NIXOS "${cfg.device}2"
        mkswap -L SWAP "${cfg.device}3"

        mount /dev/disk/by-label/NIXOS /mnt
        mkdir -p /mnt/boot
        mount /dev/disk/by-label/BOOT /mnt/boot
        swapon /dev/disk/by-label/SWAP
      fi
    '';
  };
}

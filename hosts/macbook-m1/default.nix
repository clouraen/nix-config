{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base
    ../../modules/desktop
    ../../modules/laptop
    ../../modules/users
  ];

  # MacBook-specific configurations
  networking.hostName = "nixos-macbook";

  # M1-specific settings
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  
  # Power management
  services.tlp.enable = true;
  services.thermald.enable = true;

  # Keyboard and trackpad settings
  services.xserver.libinput.enable = true;

  system.stateVersion = "23.11";
}

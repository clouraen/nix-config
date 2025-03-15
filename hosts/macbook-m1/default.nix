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

  # Networking
  networking.networkmanager.enable = true;
  networking.wireless.enable = false; # Disable wpa_supplicant in favor of NetworkManager
  
  # SSH Configuration
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  environment.systemPackages = with pkgs; [
    networkmanagerapplet # NetworkManager GUI
    gnome.nm-connection-editor
  ];

  system.stateVersion = "23.11";
}

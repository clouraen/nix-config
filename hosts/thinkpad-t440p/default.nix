{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base
    ../../modules/desktop
    ../../modules/laptop
    ../../modules/users
  ];

  # ThinkPad-specific configurations
  networking.hostName = "nixos-thinkpad";

  # Power management
  services.tlp.enable = true;
  services.thermald.enable = true;

  # Trackpoint and touchpad settings
  services.xserver.libinput.enable = true;
  services.xserver.libinput.touchpad.naturalScrolling = true;

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

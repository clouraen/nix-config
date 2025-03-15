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

  system.stateVersion = "23.11";
}

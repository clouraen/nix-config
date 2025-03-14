{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "thinkpad-t440p";
  
  # Hardware específico do ThinkPad
  services.tlp.enable = true;
  services.thinkfan.enable = true;
  
  # ThinkPad específico
  hardware.trackpoint.enable = true;
  hardware.trackpoint.emulateWheel = true;

  environment.systemPackages = with pkgs; [
    powertop
    tlp
    acpi
  ];
}

{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "macbook-m1";
  
  # Otimizações para M1
  hardware.asahi.peripheralFirmwareDirectory = "/run/current-system/sw/lib/firmware";
  hardware.asahi.addToHostName = true;

  environment.systemPackages = with pkgs; [
    asahi-scripts
    powermanagement
  ];
}

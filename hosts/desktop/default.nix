{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base
    ../../modules/desktop
    ../../modules/users
  ];

  # Desktop-specific configurations
  networking.hostName = "nixos-desktop";

  # Hardware settings
  hardware.opengl.enable = true;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  hardware.nvidia.modesetting.enable = true;

  # Display settings
  services.xserver.videoDrivers = [ "nvidia" ];

  system.stateVersion = "23.11";
}

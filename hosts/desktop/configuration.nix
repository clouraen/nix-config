{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "desktop";

  # Suporte NVIDIA
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
  
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
  };

  # Suporte CPU Intel
  hardware.cpu.intel.updateMicrocode = true;
  powerManagement.cpuFreqGovernor = "performance";

  environment.systemPackages = with pkgs; [
    nvidia-settings
    intel-gpu-tools
    htop
    glxinfo
  ];
}

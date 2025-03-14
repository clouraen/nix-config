{ config, pkgs, ... }: {
  # Configurações específicas do laptop
  networking.hostName = "laptop";
  
  # Hardware específico do laptop
  services.tlp.enable = true; # Otimização de bateria
  
  # Pacotes específicos do laptop
  environment.systemPackages = with pkgs; [
    powertop
  ];
}

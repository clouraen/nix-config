{ config, pkgs, lib, ... }:

{
  # Pacotes básicos necessários no bootstrap
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
  ];

  # Configurações de serviços iniciais
  services = {
    openssh.enable = true;
    # Outros serviços essenciais
  };

  # Scripts de ativação do sistema
  system.activationScripts = {
    bootstrap-setup = {
      text = ''
        # Criar diretórios necessários
        mkdir -p /etc/nixos/secrets
        chmod 750 /etc/nixos/secrets
        
        # Setup inicial de usuários e grupos
        # (executado apenas na primeira instalação)
      '';
      deps = [];
    };
  };

  # Configurações de hardware básicas
  boot = {
    # Configuração de kernel e inicialização 
    kernelParams = [ "quiet" "splash" ];
    # Outras configurações de boot
  };

  # Outras configurações de bootstrap
}

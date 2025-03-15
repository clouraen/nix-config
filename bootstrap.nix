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

  # Garantir que a variável de host está configurada
  system.activationScripts = {
    bootstrap-setup = {
      text = ''
        # Criar diretórios necessários
        mkdir -p /etc/nixos/secrets
        chmod 750 /etc/nixos/secrets
        
        # Setup inicial específico para o host
        echo "Configurando host: ${config.networking.hostName}"
        
        # Marca a conclusão do bootstrap
        if [ ! -f /etc/.bootstrap-done ]; then
          touch /etc/.bootstrap-done
          echo "Bootstrap inicial concluído em $(date)" > /etc/.bootstrap-done
        fi
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

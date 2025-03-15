{ config, pkgs, ... }: {
  # ...existing code...
  
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # Configurações de bootstrap
  system.activationScripts.bootstrap = {
    text = ''
      # Ações de bootstrap a serem executadas na primeira inicialização
      if [ ! -f /etc/.bootstrap-done ]; then
        echo "Executando configurações iniciais..."
        # Adicione comandos de bootstrap aqui
        
        # Marca como concluído
        touch /etc/.bootstrap-done
      fi
    '';
    deps = [];
  };

  users.users.seuusuario = {
    isNormalUser = true;
    # Usando hash criptografado para senha
    hashedPassword = "$6$xyz..."; # Hash gerado com mkpasswd
    # ...existing code...
  };
  
  # ...existing code...
}

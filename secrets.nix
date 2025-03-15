{ config, lib, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/path/to/keys.txt";
    secrets.user-password = {
      neededForUsers = true;
    };
  };

  users.users.seuusuario = {
    isNormalUser = true;
    passwordFile = config.sops.secrets.user-password.path;
    # ...existing code...
  };
}

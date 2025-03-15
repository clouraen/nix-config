{ config, lib, pkgs, ... }:

{
  imports = [ 
    # Import sops-nix module
    <sops-nix/modules/sops>
  ];

  # Enable sops
  sops = {
    # This will automatically import SSH keys as age keys
    defaultSopsFile = ../secrets/secrets.yaml;
    
    # This will automatically create a secrets directory and set permissions
    age.keyFile = "/home/${config.users.users.user.name}/.config/sops/age/keys.txt";
    
    # Settings to make sure secrets are available early in the boot process if needed
    gnupg.sshKeyPaths = [ ];
    
    # Specify secrets to be made available to the system
    secrets = {
      example_secret = {
        # Example secret configuration - uncomment if needed
        # sopsFile = ../secrets/specific_file.yaml;
        # owner = "youruser";
        # mode = "0400";
      };
    };
  };
}

{ config, pkgs, ... }: {
  # ...existing code...
  
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # ...existing code...
}

{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    hyprland.url = "github:hyprwm/Hyprland";
    end4-dots = {
      url = "github:end-4/dots-hyprland";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, hyprland, home-manager, ... }@inputs: {
    nixosConfigurations = {
      desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ 
          ./modules/partitioning
          ./hosts/desktop/configuration.nix
          ./common/default.nix 
          hyprland.nixosModules.default
          home-manager.nixosModules.home-manager
        ];
      };
      thinkpad-t440p = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ 
          ./modules/partitioning
          nixos-hardware.nixosModules.lenovo-thinkpad-t440p
          ./hosts/thinkpad-t440p/configuration.nix
          ./common/default.nix
          hyprland.nixosModules.default
          home-manager.nixosModules.home-manager
        ];
      };
      macbook-m1 = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [ 
          ./modules/partitioning
          nixos-hardware.nixosModules.apple-macbook-pro-14-m1
          ./hosts/macbook-m1/configuration.nix
          ./common/default.nix
          hyprland.nixosModules.default
          home-manager.nixosModules.home-manager
        ];
      };
    };

    apps = {
      x86_64-linux = {
        install = {
          type = "app";
          program = "${pkgs.writeShellScriptBin "nix-install" ''
            ${builtins.readFile ./scripts/install.sh}
          ''}/bin/nix-install";
        };
      };
      aarch64-linux = {
        install = {
          type = "app";
          program = "${pkgs.writeShellScriptBin "nix-install" ''
            ${builtins.readFile ./scripts/install.sh}
          ''}/bin/nix-install";
        };
      };
    };
  };
}

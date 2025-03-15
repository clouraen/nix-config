{
  description = "NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, ... }@inputs:
    let
      lib = nixpkgs.lib;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      # System configurations
      nixosConfigurations = {
        # Desktop configuration
        desktop = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/desktop
            home-manager.nixosModules.home-manager
          ];
          specialArgs = { inherit inputs; };
        };

        # ThinkPad T440p configuration
        thinkpad-t440p = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/thinkpad-t440p
            nixos-hardware.nixosModules.lenovo-thinkpad-t440p
            home-manager.nixosModules.home-manager
          ];
          specialArgs = { inherit inputs; };
        };

        # MacBook M1 configuration
        macbook-m1 = lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./hosts/macbook-m1
            nixos-hardware.nixosModules.apple-m1
            home-manager.nixosModules.home-manager
          ];
          specialArgs = { inherit inputs; };
        };
      };

      # Installation package
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          install = pkgs.writeShellScriptBin "install" (builtins.readFile ./scripts/install.sh);
        }
      );
    };
}

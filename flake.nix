{
  description = "NixOS and Homemanager Configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    # NixOS Configurations
    # sudo nixos-rebuild switch --flake .#<framework>
    nixosConfigurations = {
      framework = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
	modules = [ ./nixos/framework/configuration.nix ];
      };
    };

    homeConfigurations = {
      "pj@framework" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./home-manager/profiles/framework.nix ];
      };
    };
  };
}

{
  description = "Nix Configuration and Homemanager";

  inputs = {
    # Using unstable branch for fresh packages, perfect for an Arch companion
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    # Targets Standalone Home Manager (Arch Linux)
    # Target name should match your username@hostname format or a specific target moniker
    homeConfigurations."pj@framework" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = { inherit inputs; };
      modules = [
        ./hosts/framework/default.nix
      ];
    };
  };
}

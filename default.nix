# NixOS and Home Manager configurations — flake-free.
#
# Inputs (nixpkgs, home-manager) are pinned by nixtamal in ./nix/tamal.
# Update them with `nixtamal refresh` (see the justfile / README).
#
# Build/switch a host:
#   sudo nixos-rebuild switch --file . --attr nixosConfigurations.framework
# Build/switch a Home Manager profile:
#   nix-build --attr 'homeConfigurations."pj@framework".activationPackage' && ./result/activate
#
# The justfile wraps these; see `just` for the short forms.

{ system ? "x86_64-linux" }:

let
  inputs = import ./nix/tamal { inherit system; };

  # Home Manager builds against an explicitly-imported nixpkgs. Unfree is
  # required (e.g. claude-code), matching each profile's nixpkgs.config.
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  # A NixOS system is eval-config.nix applied to a host's module list. The
  # result carries `.config.system.build.toplevel`, which is what
  # `nixos-rebuild --file --attr <name>` builds.
  mkNixos = modules:
    import "${inputs.nixpkgs}/nixos/lib/eval-config.nix" {
      inherit system modules;
      specialArgs = { inherit inputs; };
    };

  # A Home Manager configuration; `.activationPackage` is the build target,
  # and `result/activate` performs the switch.
  mkHome = configuration:
    import "${inputs.home-manager}/modules" {
      inherit pkgs configuration;
      extraSpecialArgs = { inherit inputs; };
    };
in
{
  nixosConfigurations = {
    framework = mkNixos [ ./nixos/framework/configuration.nix ];
    installer-iso = mkNixos [ ./nixos/installer/iso.nix ];
    nas = mkNixos [ ./nixos/nas/configuration.nix ];
  };

  homeConfigurations = {
    "pj@framework" = mkHome ./home-manager/profiles/framework.nix;
    "pj@nas" = mkHome ./home-manager/profiles/headless.nix;
  };
}

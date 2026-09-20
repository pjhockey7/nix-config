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

# `system` is the *build* machine. A host that targets another architecture
# says so itself (nixos/tv/hardware-pi4.nix sets nixpkgs.hostPlatform), so
# this only has to follow whatever machine you happen to be sitting at —
# which matters for the Home Manager profiles, which have no host to ask.
{ system ? builtins.currentSystem }:

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

  # The TV boxes differ only by room: nixos/tv/common.nix carries the whole
  # appliance, and nixos/tv/hosts/<room> sets the hostname and picks its
  # launcher entries. Adding a TV means a directory and a name in this list.
  # tv-bedroom is a Raspberry Pi 4 and evaluates as aarch64-linux regardless
  # of the `system` above; see nixos/tv/hardware-pi4.nix.
  tvRooms = [ "main" "bedroom" "guest" ];
  tvConfigurations = builtins.listToAttrs (
    map (room: {
      name = "tv-${room}";
      value = mkNixos [ ./nixos/tv/hosts/${room} ];
    }) tvRooms
  );
in
{
  nixosConfigurations = {
    framework = mkNixos [ ./nixos/framework/configuration.nix ];
    installer-iso = mkNixos [ ./nixos/installer/iso.nix ];
    nas = mkNixos [ ./nixos/nas/configuration.nix ];
  } // tvConfigurations;

  homeConfigurations = {
    "pj@framework" = mkHome ./home-manager/profiles/framework.nix;
    "pj@nas" = mkHome ./home-manager/profiles/headless.nix;
    # One profile for every TV: the boxes have separate disks, so nothing
    # about `pj` needs to differ between them.
    "pj@tv" = mkHome ./home-manager/profiles/tv.nix;
  };
}

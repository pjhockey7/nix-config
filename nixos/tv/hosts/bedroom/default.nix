# The bedroom box — a Raspberry Pi 4, so it imports ../../hardware-pi4.nix
# instead of the shared x86 hardware-configuration.nix. Everything else about
# the appliance is identical to the other rooms.
#
# Cut a card:  nix-build -A nixosConfigurations.tv-bedroom.config.system.build.sdImage
# See README, "Installing onto a Raspberry Pi 4".

{ config, lib, pkgs, ... }:

let
  apps = import ../../apps.nix { inherit config lib pkgs; };
in
{
  imports = [
    ../../common.nix
    ../../hardware-pi4.nix
  ];

  networking.hostName = "tv-bedroom";

  services.tv.apps = with apps; [
    jellyfin
    netflix
    youtube
    hulu
    max
    browser
    reboot
    powerOff
  ];
}

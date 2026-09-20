# The guest-room box.
#
# A short menu on purpose: a guest wants to find Jellyfin, not scroll past
# five services they can't sign into. `browser` stays as the escape hatch for
# someone who wants to log into their own account for the weekend.

{ config, lib, pkgs, ... }:

let
  apps = import ../../apps.nix { inherit config lib pkgs; };
in
{
  imports = [
    ../../common.nix
    ../../hardware-configuration.nix
  ];

  networking.hostName = "tv-guest";

  services.tv.apps = with apps; [
    jellyfin
    youtubeTv
    browser
    reboot
    powerOff
  ];
}

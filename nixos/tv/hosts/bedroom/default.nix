# The bedroom box.

{ config, lib, pkgs, ... }:

let
  apps = import ../../apps.nix { inherit config lib pkgs; };
in
{
  imports = [ ../../common.nix ];

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

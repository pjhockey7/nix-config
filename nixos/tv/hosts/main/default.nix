# The living-room box — the one with every service logged in.

{ config, lib, pkgs, ... }:

let
  apps = import ../../apps.nix { inherit config lib pkgs; };
in
{
  imports = [
    ../../common.nix
    ../../hardware-configuration.nix
  ];

  networking.hostName = "tv-main";

  services.tv.apps = with apps; [
    jellyfin
    netflix
    youtubeTv
    hulu
    max
    browser
    reboot
    powerOff
  ];
}

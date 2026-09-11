# Receiving streams from phones, without Chromecast.
#
# Two receivers, one per ecosystem:
#
#   UxPlay        AirPlay screen mirroring + audio, for iPhone/Mac. This is
#                 the only option that speaks what modern iOS actually sends;
#                 Kodi's legacy "AirPlay" support does not.
#   gmediarender  UPnP/DLNA renderer, for Android (BubbleUPnP and friends).
#
# Both run as *user* services inside the TV session rather than as system
# daemons. UxPlay needs the session's Wayland socket to draw on, and both need
# its PipeWire socket to play to — the upstream `services.gmediarender` module
# runs under DynamicUser with ProtectHome, which can reach neither. They are
# started by the launcher (see ../modules/tv) once WAYLAND_DISPLAY exists.
#
# Jellyfin has its own path and needs nothing here: Jellyfin Media Player
# registers as a controllable session, so "Play On" from the phone app targets
# this box directly.

{ config, lib, pkgs, ... }:

let
  # Shown in the AirPlay picker and in DLNA app device lists.
  friendlyName = config.networking.hostName;

  # Arbitrary but must stay stable: DLNA controllers key their device list on
  # it, and a changing UUID shows up as a new renderer every reboot.
  rendererUuid = "b1d3f0a2-5c4e-4a7b-9f61-0a2b3c4d5e6f";
  rendererPort = 49494;
in
{
  # Both protocols discover over mDNS/SSDP; without this the box is invisible
  # even though the services are running.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      userServices = true;
    };
  };

  systemd.user.services.uxplay = {
    description = "UxPlay — AirPlay mirroring receiver";
    partOf = [ "tv-session.target" ];
    wantedBy = [ "tv-session.target" ];
    serviceConfig = {
      # -p pins the legacy fixed ports so the firewall rules below can be
      #    static (without it UxPlay picks random ports at startup).
      # -nh stops it appending the hostname to the advertised name.
      # -fs starts mirrored output fullscreen.
      ExecStart = "${lib.getExe pkgs.uxplay} -n ${lib.escapeShellArg friendlyName} -nh -p -fs";
      Restart = "always";
      RestartSec = 5;
    };
  };

  systemd.user.services.gmediarender = {
    description = "gmediarender — UPnP/DLNA renderer";
    partOf = [ "tv-session.target" ];
    wantedBy = [ "tv-session.target" ];
    serviceConfig = {
      ExecStart = lib.concatStringsSep " " [
        (lib.getExe pkgs.gmrender-resurrect)
        "--friendly-name=${lib.escapeShellArg friendlyName}"
        "--port=${toString rendererPort}"
        "--uuid=${rendererUuid}"
      ];
      Restart = "always";
      RestartSec = 5;
    };
  };

  networking.firewall = {
    # 7000/7001/7100 AirPlay (UxPlay -p), 49494 the DLNA renderer's HTTP port.
    allowedTCPPorts = [
      7000
      7001
      7100
      rendererPort
    ];
    # 6000/6001/7011 AirPlay streaming (UxPlay -p), 1900 SSDP discovery.
    allowedUDPPorts = [
      1900
      6000
      6001
      7011
    ];
  };

  # Deliberately NOT enabling shairport-sync: UxPlay already receives AirPlay
  # audio, and running both means two daemons advertising RAOP over the same
  # mDNS names. Enable it only if you drop UxPlay.
}

# The launcher catalog, shared by every TV host.
#
# An attrset rather than a list, so each host picks the entries it wants:
#
#     services.tv.apps = with apps; [ jellyfin youtube netflix ];
#
# A list defined here would force hosts that want fewer entries to
# `lib.mkForce` the whole thing back out again.

{ config, lib, pkgs }:

let
  # youtube.com/tv (the leanback/10-foot UI, and the one that pairs with a
  # phone via "Link with TV code") redirects to the desktop site unless it
  # sees a TV User-Agent. Refresh this if YouTube starts bouncing you.
  tvUserAgent =
    "Mozilla/5.0 (SMART-TV; Linux; Tizen 5.0) AppleWebKit/537.36 "
    + "(KHTML, like Gecko) 69.0.3497.106 Safari/537.36";
in
{
  jellyfin = {
    name = "Jellyfin";
    # Jellyfin Desktop (formerly Jellyfin Media Player) — mpv-based, so it
    # direct-plays codecs a browser would force the server to transcode.
    # It also registers as a controllable session, which is what makes
    # "Play On" from the Jellyfin phone app target this box.
    #
    # Fullscreen is a setting inside the app (Settings > Video), not a
    # CLI flag — set it once on first run and it persists.
    command = "${lib.getExe pkgs.jellyfin-media-player}";
  };

  netflix = {
    name = "Netflix";
    url = "https://www.netflix.com/browse";
  };

  youtube = {
    name = "YouTube";
    url = "https://www.youtube.com/tv";
    userAgent = tvUserAgent;
  };

  hulu = {
    name = "Hulu";
    url = "https://www.hulu.com";
  };

  max = {
    name = "Max";
    url = "https://play.max.com";
  };

  browser = {
    name = "Browser";
    # An escape hatch: some services only let you log in, or re-auth,
    # through a normal browsing session.
    url = "https://duckduckgo.com";
  };

  reboot = {
    name = "Reboot";
    command = "${config.systemd.package}/bin/systemctl reboot";
  };

  powerOff = {
    name = "Power Off";
    command = "${config.systemd.package}/bin/systemctl poweroff";
  };
}

# `tv` — an open streaming box.
#
# Boots straight into a TV launcher (see ../modules/tv). The DRM services run
# as isolated Chrome kiosk windows because Chrome is the only browser shipping
# Widevine on Linux; Jellyfin runs natively through Jellyfin Desktop (mpv),
# which direct-plays instead of making the `server` host transcode.
#
# Expect Widevine L3 / "Software Secure" — 720p-1080p, no 4K, HDR, Dolby
# Vision or Atmos. That is a Linux-wide DRM ceiling on every architecture,
# not a limit of this hardware.

{ config, lib, pkgs, ... }:

let
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKoVu+kHYw/JJ/JUykTh5y2jejlVui8bhhOn+RYxSpDn pjhockey7@gmail.com"
  ];

  # youtube.com/tv (the leanback/10-foot UI, and the one that pairs with a
  # phone via "Link with TV code") redirects to the desktop site unless it
  # sees a TV User-Agent. Refresh this if YouTube starts bouncing you.
  tvUserAgent =
    "Mozilla/5.0 (SMART-TV; Linux; Tizen 5.0) AppleWebKit/537.36 "
    + "(KHTML, like Gecko) 69.0.3497.106 Safari/537.36";
in
{
  imports = [
    ./hardware-configuration.nix
    ../modules/tv
    ./services/casting.nix
  ];

  # Flakes intentionally disabled — inputs pinned by nixtamal (see repo default.nix).
  nix.settings.experimental-features = [ "nix-command" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # An appliance should look like one while booting, not like a kernel log.
  boot.plymouth.enable = true;
  boot.kernelParams = [ "quiet" "splash" ];

  networking.hostName = "tv";
  networking.firewall.enable = true;

  # Ethernet is strongly preferred for a box that streams; wifi is here so a
  # move to a different room doesn't brick it. Configure wifi over SSH with
  # `iwctl`, since there's no shell on the TV itself.
  networking.useNetworkd = true;
  networking.wireless.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = false;
  };
  systemd.network.networks = {
    "30-ethernet" = {
      matchConfig.Name = "en*";
      networkConfig.DHCP = "yes";
    };
    "40-wireless" = {
      matchConfig.Name = "wl*";
      networkConfig.DHCP = "yes";
    };
  };

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # The only way in — the box has no terminal of its own.
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
    settings.PasswordAuthentication = false;
  };
  users.users.root.openssh.authorizedKeys.keys = authorizedKeys;

  users.users.pj = {
    isNormalUser = true;
    description = "pj";
    extraGroups = [ "wheel" "video" "audio" "input" ];
    openssh.authorizedKeys.keys = authorizedKeys;
  };
  security.sudo.wheelNeedsPassword = false;

  # google-chrome (Widevine) and the Intel media driver are unfree.
  nixpkgs.config.allowUnfree = true;
  hardware.enableRedistributableFirmware = true;

  services.tv = {
    enable = true;
    user = "pj";

    apps = [
      {
        name = "Jellyfin";
        # Jellyfin Desktop (formerly Jellyfin Media Player) — mpv-based, so it
        # direct-plays codecs a browser would force the server to transcode.
        # It also registers as a controllable session, which is what makes
        # "Play On" from the Jellyfin phone app target this box.
        #
        # Fullscreen is a setting inside the app (Settings > Video), not a
        # CLI flag — set it once on first run and it persists.
        command = "${lib.getExe pkgs.jellyfin-media-player}";
      }
      {
        name = "Netflix";
        url = "https://www.netflix.com/browse";
      }
      {
        name = "YouTube";
        url = "https://www.youtube.com/tv";
        userAgent = tvUserAgent;
      }
      {
        name = "Hulu";
        url = "https://www.hulu.com";
      }
      {
        name = "Max";
        url = "https://play.max.com";
      }
      {
        name = "Browser";
        # An escape hatch: some services only let you log in, or re-auth,
        # through a normal browsing session.
        url = "https://duckduckgo.com";
      }
      {
        name = "Reboot";
        command = "${config.systemd.package}/bin/systemctl reboot";
      }
      {
        name = "Power Off";
        command = "${config.systemd.package}/bin/systemctl poweroff";
      }
    ];
  };

  # Hardware video decode. Unprotected video (YouTube, Jellyfin) uses it;
  # Widevine-protected streams decode in software no matter what.
  hardware.graphics = {
    enable = true;
    extraPackages = lib.optionals pkgs.stdenv.hostPlatform.isx86_64 (
      with pkgs;
      [
        intel-media-driver # Gen9+ / N-series iGPUs
        vpl-gpu-rt
      ]
    );
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # The launcher theme asks for this by name; without it rofi silently falls
  # back to a font that won't be sized for a 10-foot UI.
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
  ];

  environment.systemPackages = with pkgs; [
    git
    vim
    btop
    jellyfin-media-player
    libva-utils # `vainfo` — confirm hardware decode actually came up
    wev # identify what keycodes your remote sends, for rc.xml
  ];

  system.stateVersion = "26.05";
}

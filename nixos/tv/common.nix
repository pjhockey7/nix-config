# Everything shared by every TV box.
#
# A host (nixos/tv/hosts/<room>) adds only what actually differs: its
# hostname, its launcher entries, and — if its remote disagrees with the
# default keymap — its own rc.xml. See nixos/tv/hosts/main for the shape.
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
in
{
  # Hardware is *not* imported here — each host picks its own, because the
  # boxes are no longer all the same machine. The x86 rooms import the shared
  # ./hardware-configuration.nix (they address their filesystems by label, so
  # one file covers them); a Pi imports ./hardware-pi4.nix instead.
  imports = [
    ../modules/tv
    ./services/casting.nix
  ];

  # Flakes intentionally disabled — inputs pinned by nixtamal (see repo default.nix).
  nix.settings.experimental-features = [ "nix-command" ];

  # UEFI, which is right for every x86 box but not for a Pi — mkDefault so
  # hardware-pi4.nix can switch to extlinux without lib.mkForce.
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  # An appliance should look like one while booting, not like a kernel log.
  boot.plymouth.enable = true;
  boot.kernelParams = [ "quiet" "splash" ];

  # networking.hostName is set per host.
  networking.firewall.enable = true;

  # With several boxes on the LAN, `ssh tv-bedroom.local` beats hunting for
  # whichever address DHCP handed out this week. (avahi.openFirewall, on by
  # default, is what lets mDNS through the firewall enabled above.)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

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

  # `apps` is set per host, from the catalog in ./apps.nix.
  services.tv = {
    enable = true;
    user = "pj";
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

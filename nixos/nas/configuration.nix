{ config, pkgs, ... }:

let
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKoVu+kHYw/JJ/JUykTh5y2jejlVui8bhhOn+RYxSpDn pjhockey7@gmail.com"
  ];
in
{
  imports = [ ./hardware-configuration.nix ];

  # Flakes intentionally disabled — inputs pinned by nixtamal (see repo default.nix).
  nix.settings.experimental-features = [ "nix-command" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ZFS support for the `nas` data pool.
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  networking.hostId = "eaa96110";
  services.zfs.autoScrub.enable = true;
  # Auto-import the pool at boot (first import required `-f` once because the
  # pool was last written by FreeBSD; hostid now matches so no `-f` needed).
  boot.zfs.extraPools = [ "nas" ];

  networking.hostName = "nas";
  networking.useDHCP = true;
  networking.firewall.enable = true;

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
    settings.PasswordAuthentication = false;
  };

  users.users.root.openssh.authorizedKeys.keys = authorizedKeys;

  users.users.pj = {
    isNormalUser = true;
    description = "pj";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = authorizedKeys;
  };

  # Passwordless sudo for wheel — SSH is key-only, so this is the bootstrap path.
  security.sudo.wheelNeedsPassword = false;

  # NFS export of the `nas` pool for Linux clients on the LAN.
  services.nfs.server = {
    enable = true;
    exports = ''
      /nas 172.16.0.0/24(rw,sync,no_subtree_check,no_root_squash)
    '';
  };
  # NFSv4 uses TCP 2049. Restrict to the LAN via the export ACL above.
  networking.firewall.allowedTCPPorts = [ 2049 ];

  environment.systemPackages = with pkgs; [
    git
    vim
    btop
    ncdu
    tmux
  ];

  system.stateVersion = "25.11";
}

{ config, pkgs, ... }:

let
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKoVu+kHYw/JJ/JUykTh5y2jejlVui8bhhOn+RYxSpDn pjhockey7@gmail.com"
  ];
in
{
  imports = [ ./hardware-configuration.nix ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ZFS support for the `nas` data pool.
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  networking.hostId = "eaa96110";
  services.zfs.autoScrub.enable = true;
  # After the first manual `zpool import -f nas` (needed once because the pool
  # was last written by FreeBSD), uncomment to auto-import on every boot:
  # boot.zfs.extraPools = [ "nas" ];

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

  # Samba share for the `nas` pool.
  # Note: pj needs a Samba password set once after first boot:
  #   sudo smbpasswd -a pj
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "nas";
        "netbios name" = "nas";
        "security" = "user";
        "map to guest" = "never";
      };
      nas = {
        "path" = "/nas";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "pj";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    btop
    ncdu
    tmux
  ];

  system.stateVersion = "25.11";
}

{ config, pkgs, ... }:

let
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKoVu+kHYw/JJ/JUykTh5y2jejlVui8bhhOn+RYxSpDn pjhockey7@gmail.com"
  ];
  nasHost = "172.16.0.35";
in
{
  imports = [
    ./hardware-configuration.nix
    ./services/jellyfin.nix
    # ./services/photoprism.nix
    # ./services/caddy.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "server";
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

  security.sudo.wheelNeedsPassword = false;

  # Mount the NAS's NFS export at /nas.
  # `x-systemd.automount` mounts lazily on first access and doesn't block boot
  # if the NAS is offline. `nofail` keeps the server bootable regardless.
  fileSystems."/nas" = {
    device = "${nasHost}:/nas";
    fsType = "nfs";
    options = [
      "nfsvers=4.2"
      "x-systemd.automount"
      "noauto"
      "nofail"
      "x-systemd.idle-timeout=600"
    ];
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    btop
    ncdu
    tmux
    nfs-utils
  ];

  system.stateVersion = "25.11";
}

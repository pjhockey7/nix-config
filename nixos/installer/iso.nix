# Headless NixOS installer ISO with SSH pre-authorized.
#
# Build:  nix-build --attr nixosConfigurations.installer-iso.config.system.build.isoImage
# Flash:  sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress conv=fsync
# Use:    boot the target, find its IP, `ssh root@<ip>` — no password prompt.

{ pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKoVu+kHYw/JJ/JUykTh5y2jejlVui8bhhOn+RYxSpDn pjhockey7@gmail.com"
  ];

  # ZFS support so the NAS's existing pool can be inspected/imported pre-install.
  boot.supportedFilesystems = [ "zfs" ];
  # Required by ZFS. Only relevant to the live env; the installed system sets its own.
  networking.hostId = "deadbeef";

  environment.systemPackages = with pkgs; [
    git
    vim
    parted
    tmux
  ];

  time.timeZone = "America/Los_Angeles";
}

# PLACEHOLDER — replace this whole file.
#
# On the real box, boot the installer and run:
#
#     nixos-generate-config --root /mnt
#
# then copy /mnt/etc/nixos/hardware-configuration.nix over this file. Nothing
# else needs to change: ../modules/tv and ./services/casting.nix are
# hardware-agnostic, and common.nix already guards the Intel VA-API drivers
# behind an x86_64 check.
#
# Every TV host shares this one file, which holds only while they address
# their filesystems identically. Label the partitions at install time
# (`e2label /dev/... NIXOS`, `fatlabel /dev/... BOOT`) and keep the generated
# file on `by-label` rather than the `by-uuid` nixos-generate-config writes —
# otherwise the first box's UUIDs end up baked into all of them. A box that
# really is different drops its own copy into nixos/tv/hosts/<room>/ and
# imports it there.
#
# The values below are fake. They exist only so `nix-build` can evaluate and
# type-check the host before you have hardware — the closure it produces will
# not boot.

{ config, lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/PLACEHOLDER-ROOT";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/PLACEHOLDER-BOOT";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

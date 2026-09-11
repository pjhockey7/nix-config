# PLACEHOLDER — replace this whole file.
#
# On the real box, boot the installer and run:
#
#     nixos-generate-config --root /mnt
#
# then copy /mnt/etc/nixos/hardware-configuration.nix over this file. Nothing
# else in the `tv` host needs to change: ../modules/tv and ./services/casting.nix
# are hardware-agnostic, and configuration.nix already guards the Intel VA-API
# drivers behind an x86_64 check.
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

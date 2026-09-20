# Raspberry Pi 4 (aarch64) — hardware + bootable SD image.
#
# This replaces hardware-configuration.nix for a Pi host. It is *not*
# nixos-generate-config output: a Pi's filesystems come from the SD image
# module (labelled FIRMWARE + NIXOS_SD), so there is nothing to scan.
#
# Importing the sd-image module permanently — rather than only when building
# the card — means the closure on the card and the closure a later
# `nixos-rebuild switch` produces are the same, and you can re-cut a card from
# the same host attribute at any time:
#
#   nix-build -A nixosConfigurations.tv-bedroom.config.system.build.sdImage
#
# Boot chain: Pi firmware reads config.txt → u-boot.bin → extlinux.conf on the
# ext4 root → kernel. Mainline (not the vendor rpi kernel), because mainline
# is what cache.nixos.org has aarch64 builds of; linuxPackages_rpi4 would mean
# compiling a kernel under qemu.
#
# What the Pi 4 gives up versus the x86 boxes: Chrome has no VA-API driver on
# v3d, so every stream — DRM or not — decodes on the CPU. 1080p H.264 is fine,
# 1080p VP9/AV1 (i.e. YouTube) is not; the leanback UI will settle at 720p.
# Jellyfin goes through mpv, which can use the Pi's dedicated H.264 block.

{ config, lib, pkgs, modulesPath, ... }:

{
  # Brings fileSystems."/" (NIXOS_SD) and /boot/firmware (FIRMWARE), the
  # first-boot root resize, and config.system.build.sdImage.
  imports = [ (modulesPath + "/installer/sd-card/sd-image.nix") ];

  nixpkgs.hostPlatform = "aarch64-linux";

  # The Pi has no UEFI. common.nix defaults systemd-boot on for the x86
  # boxes; plain `false` here outranks its mkDefault.
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Serial as well as HDMI: the box is headless until the launcher comes up,
  # and a USB-TTL cable is the only way to watch it fail before sshd starts.
  # (`quiet splash` comes from common.nix and is merged with these.)
  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "console=tty0"
  ];
  boot.consoleLogLevel = lib.mkDefault 7;

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "usbhid"
    "usb_storage"
  ];

  # Chrome on a 10-foot UI is the memory hog here, and the SD card is a bad
  # place to page to. zram costs CPU the A72s can spare.
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # The firmware partition is written once, when the card is cut —
  # `nixos-rebuild switch` on the running Pi does not touch it. Anything you
  # change below requires re-flashing (or hand-editing /boot/firmware).
  sdImage = {
    # 30MiB (the default) has no room for u-boot plus the pi4 DTBs.
    firmwareSize = 64;

    populateFirmwareCommands =
      let
        configTxt = pkgs.writeText "config.txt" ''
          # Chain-load u-boot, which then reads extlinux.conf from the root fs.
          kernel=u-boot.bin
          arm_64bit=1

          # u-boot wants the UART alive whether or not anything is attached.
          enable_uart=1

          # Keep the firmware from smashing the mainline kernel's framebuffer
          # to draw a low-voltage/overtemp warning over the top of it.
          avoid_warnings=1

          [pi4]
          enable_gic=1
          armstub=armstub8-gic.bin
          disable_overscan=1
          arm_boost=1

          # Without this there is no DRM device at all on a mainline kernel,
          # so labwc has nothing to start on and the box boots to a black
          # screen you can only diagnose over SSH. cma-256 is the framebuffer
          # budget; raise it to cma-512 on a 4GB+ Pi if 4K output stutters.
          dtoverlay=vc4-kms-v3d,cma-256

          # Attach the on-board Bluetooth to the kernel's UART HCI driver.
          # Needed for a BT remote to pair at all.
          dtparam=krnbt=on

          # A TV that is switched off when the Pi boots presents no EDID, and
          # the kernel then brings up no output — powering the TV on later
          # does not fix it. Uncomment to force a mode regardless of EDID
          # (`D` = digital/HDMI, forced on):
          # (also add video=HDMI-A-1:1920x1080@60D to boot.kernelParams)
        '';
      in
      ''
        (cd ${pkgs.raspberrypifw}/share/raspberrypi/boot && cp bootcode.bin fixup*.dat start*.elf $NIX_BUILD_TOP/firmware/)
        cp ${pkgs.ubootRaspberryPiAarch64}/u-boot.bin firmware/u-boot.bin
        cp ${pkgs.raspberrypi-armstubs}/armstub8-gic.bin firmware/armstub8-gic.bin
        cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-4-b.dtb firmware/
        cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-400.dtb firmware/
        cp ${configTxt} firmware/config.txt
      '';

    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };
}

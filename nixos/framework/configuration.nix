# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../modules/steam.nix
    ];

  # Flakes intentionally disabled — inputs are pinned by nixtamal (see repo
  # default.nix / nix/tamal). `nix-command` kept for the modern CLI.
  nix.settings.experimental-features = [ "nix-command" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  #boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelPackages = pkgs.linuxPackagesFor (
    pkgs.linux_latest.override {
      argsOverride = rec {
        version = "7.0.6";
        modDirVersion = "7.0.6";
        src = pkgs.fetchurl {
          url = "mirror://kernel/linux/kernel/v7.x/linux-${version}.tar.xz";
          sha256 = "08vm18wx6399phzgr3wz94yga3ab4fyca79445ygvbspm904996b";
        };
      };
    }
  ); 


  networking.hostName = "framework"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking using iwd
  networking.wireless.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = false; # Let networkd handle IPs
  };

  # Use systemd-networkd instaed of NetworkManager
  networking.useNetworkd = true;

  # Configure DHCP for both Ethernet and Wireless
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

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.pj = {
    isNormalUser = true;
    description = "pj";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "lp" ];
    packages = with pkgs; [
      brightnessctl
      git
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  # Enable unfree firmware blobs
  hardware.enableRedistributableFirmware = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim
  #  wget
  ];
  environment.pathsToLink = [ "/share/xdg-desktop-portal" "/share/applications" ];

  # Wayland graphics support
  hardware.graphics = {
    enable = true;
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  hardware.bluetooth = 
  {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        FastConnectable = false;
        # Enable some common profiles
        Enable = "Source,Sink,Media,Socket";
        # Force specific controller mode if needed
        ControllerMode = "dual";
      };
    };
  };

  fonts.packages = with pkgs; [
    font-awesome
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd start-hyprland";
	      user = "greeter";
      };
    };
  };

  services.blueman.enable = true;

  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}

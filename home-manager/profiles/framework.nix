{ pkgs, ... }: {
  imports = [
    ../firefox.nix
    ../git.nix
    ../home-manager.nix
    ../keepassxc.nix
    ../rofi/rofi.nix
    ../shell.nix
    ../neovim.nix
    ../ai/claude.nix
    ../desktops/hyprland.nix
    ../desktops/hyprlock.nix
    ../terminals/ghostty.nix
    ../waybar/waybar.nix
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Machine-specific user environment context
  home.username = "pj";          # Replace with your actual Arch username
  home.homeDirectory = "/home/pj"; # Replace with your actual home path
  
  # State version controls backward-compatible defaults. 
  # Leave this at the version you originally installed.
  home.stateVersion = "26.05"; 

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Graphical-only packages; the headless profile shares ../home-manager.nix,
  # so desktop apps live here instead.
  home.packages = with pkgs; [
    vlc # plays mkv/h264/h265 out of the box
  ];
}

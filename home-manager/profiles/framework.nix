{ pkgs, ... }: {
  imports = [
    ../firefox.nix
    ../git.nix
    ../home-manager.nix
    ../keepassxc.nix
    ../rofi/rofi.nix
    ../shell.nix
    ../desktops/hyprland.nix
    ../terminals/ghostty.nix
    ../waybar/waybar.nix
  ];

  # Machine-specific user environment context
  home.username = "pj";          # Replace with your actual Arch username
  home.homeDirectory = "/home/pj"; # Replace with your actual home path
  
  # State version controls backward-compatible defaults. 
  # Leave this at the version you originally installed.
  home.stateVersion = "26.05"; 

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}

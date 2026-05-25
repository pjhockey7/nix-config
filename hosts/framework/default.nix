{ pkgs, ... }: {
  imports = [
    ../../modules/home/firefox.nix
    ../../modules/home/git.nix
    ../../modules/home/home-manager.nix
    ../../modules/home/rofi/rofi.nix
    ../../modules/home/shell.nix
    ../../modules/home/desktops/hyprland.nix
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

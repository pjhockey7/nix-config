{ pkgs, ... }: {
  imports = [
    ../git.nix
    ../home-manager.nix
    ../shell.nix
    ../neovim.nix
    ../ai/claude.nix
  ];

  nixpkgs.config.allowUnfree = true;

  home.username = "pj";
  home.homeDirectory = "/home/pj";

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}

{ ... }: {
  # The TV box's user environment is deliberately thin: the interface itself
  # is system-level (nixos/modules/tv), so this profile only covers what you
  # touch over SSH when something needs debugging.
  imports = [
    ../git.nix
    ../home-manager.nix
    ../shell.nix
    ../neovim.nix
  ];

  nixpkgs.config.allowUnfree = true;

  home.username = "pj";
  home.homeDirectory = "/home/pj";

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}

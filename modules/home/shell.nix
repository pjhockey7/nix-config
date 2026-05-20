{ pkgs, ... }: {
  # Installs packages directly into your user profile store
  home.packages = with pkgs; [
    fastfetch
    ripgrep
    fd
  ];

  programs.zsh = {
    enable = true;
    shellAliases = {
      # Custom alias to easily rebuild your user configuration from anywhere
      hms = "home-manager switch --flake ~/src/nix-config#myuser@arch-laptop";
    };
  };
}

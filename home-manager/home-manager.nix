{ pkgs, ... }: {
  programs.home-manager = {
    enable = true;
  };

  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    # x11.enable = true; # Uncomment if you use XWayland apps often
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };

  # Installs packages directly into your user profile store
  home.packages = with pkgs; [
    signal-desktop
    python3
    pavucontrol
    unzip
    zip
    qbittorrent

  ];
}

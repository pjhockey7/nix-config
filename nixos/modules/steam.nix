{ pkgs, ... }: {
  # Enable the first-class Steam module
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
}

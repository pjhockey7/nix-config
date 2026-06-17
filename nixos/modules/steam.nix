{ pkgs, ... }: {
  # Enable the first-class Steam module
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;

    # Automatically injects custom Proton versions (like Proton-GE) into Steam
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };
}

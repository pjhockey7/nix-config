{ pkgs, ... }: {
  programs.git = {
    enable = true;
    userName = "pjhockey7";
    userEmail = "pjhockey7@gmail.com";
    extraConfig = {
      init.defaultBranch = "master";
    };
  };
}

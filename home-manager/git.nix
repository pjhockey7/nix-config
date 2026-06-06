{ pkgs, ... }: {
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "pjhockey7";
        email = "pjhockey7@gmail.com";
      };
      init = {
        defaultBranch = "master";
      };
      core = {
        editor = "nvim";
      };
    };
  };
}

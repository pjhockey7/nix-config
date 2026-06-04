{ pkgs, ... }: {
  programs.git = {
    settings = {
        user = {
            email   = "pjhockey7@gmail.com";
            name    = "pjhockey7";
        };
        init.defaultBranch = "master";
    };
    
    enable = true;
  };
} 

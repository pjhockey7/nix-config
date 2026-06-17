{ pkgs, ... }: {
  programs.keepassxc = {
  enable = true;

    settings = {
      Browser.Enabled = true;

      GUI = {
        AdvancedSettings = true;
        ApplicationTheme = "dark";
        CompactMode = "false";
        HidePasswords = true;
      };
    };
  };
} 

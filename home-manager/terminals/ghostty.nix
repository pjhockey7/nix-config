{ pkgs, ... }: {

    programs.ghostty = {
        enable = true;
        settings = {
            background-opacity = 0.95;
            theme = "Dracula";
            font-size = 10;
            adjust-cursor-height = 15;
        };
    };
}

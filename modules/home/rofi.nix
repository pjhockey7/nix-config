{ pkgs, ... }: {
    programs.rofi = {
        enable = true;
        
        font = "Jetbrains Mono 12";
        location = "center";

        modes = [
            "drun"
        ];
    };
}

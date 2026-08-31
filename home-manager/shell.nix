{ pkgs, ... }: {

    programs.bash = {
        enable = true;

        enableCompletion = true;
        historyFileSize = -1;
        historySize = 10000;

        historyIgnore = [
            "ls"
            "cd"
            "exit"
            "history"
        ];

        initExtra = ''
            export PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
            set -o vi
        '';

        sessionVariables = {
            EDITOR = "nvim";
            VISUAL = "nvim";
            STM32_PRG_PATH = "/home/pj/tools/bin";
        };

        shellAliases = {
            # Custom alias to easily rebuild your user configuration from anywhere
            #hms = "nix-build ~/repos/pjhockey7/nix-config -A 'homeConfigurations.\"pj@framework\".activationPackage' -o /tmp/hm && /tmp/hm/activate";
            ls = "ls --color=auto";
            ll = "ls -la";
            la = "ls -a";
            nv = "nvim";
        };
    };
}

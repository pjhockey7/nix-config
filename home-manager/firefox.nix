{ pkgs, ... }: {
    programs.firefox = {
        enable = true;

        languagePacks = [ "en-US" ];
        policies = {
            BlockAboutConfig = true;
            DefaultDownloadDirectory = "\${home}/Downloads";
            DisableTelemetry = true;

            ExtensionSettings = {
                "uBlock0@raymondhill.net" = {
                default_area = "menupanel";
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
                installation_mode = "force_installed";
                private_browsing = true;
                };
            };
        };

        profiles = {
            default = {
                id = 0;
                name = "default";
                isDefault = true;
                settings = {
                    "browser.search.defaultenginename" = "DuckDuckGo";
                    "signon.rememberSignons" = false;

		    "extensions.activeThemeID" = "dark@mozilla.org";
		    "layout.css.prefers-color-scheme.content-override" = 0;

		    "browser.startup.homepage_override.mstone" = "ignore";
                };
            };
        };
    };
}

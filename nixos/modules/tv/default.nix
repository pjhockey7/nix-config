# A TV-appliance session.
#
# labwc (a small wlroots compositor) autostarts a fullscreen rofi launcher.
# Picking an entry runs that app in the *foreground*; when the app exits you
# land back on the launcher. Apps are modal, like a set-top box — and `Home`
# closes the focused app, which is the escape hatch Chrome's `--kiosk` mode
# otherwise doesn't give you.
#
# labwc rather than cage specifically because cage has no keybindings: a
# `--kiosk` Chrome window with no exit affordance (Netflix, Max) would be
# unescapable from a remote.
#
# Nothing below is really TV-specific. `services.tv.apps` is a list of names,
# each with either a `url` (opened as an isolated Chrome kiosk window) or a
# `command`.

{ config, lib, pkgs, ... }:

let
  cfg = config.services.tv;

  # Used for per-app Chrome profile directories and derivation names.
  slug =
    name:
    lib.toLower (builtins.replaceStrings [ " " "." "/" "+" ] [ "-" "-" "-" "-" ] name);

  # Each web app gets its own --user-data-dir. Logins, cookies and a wedged
  # renderer all stay contained to a single service, and one service's Chrome
  # upgrade can't invalidate another's session.
  mkWebApp =
    app:
    let
      args =
        [ "--app=${lib.escapeShellArg app.url}" ]
        ++ lib.optional (app.userAgent != null) "--user-agent=${lib.escapeShellArg app.userAgent}"
        ++ cfg.browserFlags;
    in
    pkgs.writeShellScript "tv-app-${slug app.name}" ''
      profile="$HOME/.local/share/tv/${slug app.name}"
      mkdir -p "$profile"
      exec ${lib.getExe cfg.browser} \
        --user-data-dir="$profile" \
        ${lib.concatStringsSep " \\\n    " args}
    '';

  mkCommandApp = app: pkgs.writeShellScript "tv-app-${slug app.name}" ''
    exec ${app.command}
  '';

  runnerFor = app: if app.url != null then mkWebApp app else mkCommandApp app;

  # `|| true` so a crashing app drops you back to the launcher instead of
  # taking the loop (and therefore the whole session) down with it.
  cases = lib.concatMapStringsSep "\n      " (
    app: "${lib.escapeShellArg app.name}) ${runnerFor app} || true ;;"
  ) cfg.apps;

  launcher = pkgs.writeShellApplication {
    name = "tv-launcher";
    runtimeInputs = [ pkgs.rofi ];
    text = ''
      # Hand the session environment to `systemd --user` so the receiver
      # services (uxplay, gmediarender) can find this login's Wayland and
      # PipeWire sockets. Without this they start with an empty environment
      # and have no display to draw on / no sink to play to.
      systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP || true
      systemctl --user start tv-session.target || true

      while :; do
        if ! choice=$(printf '%s\n' ${lib.escapeShellArgs (map (a: a.name) cfg.apps)} \
             | rofi -dmenu -i -no-custom -p "" -theme ${cfg.theme}); then
          # rofi exits non-zero when dismissed. There is nothing "behind" the
          # launcher on a TV, so just show it again — the sleep keeps a
          # genuinely broken rofi from spinning the CPU.
          sleep 1
          continue
        fi
        case "$choice" in
          ${cases}
        esac
      done
    '';
  };

  session = pkgs.writeShellScript "tv-session" ''
    export XDG_CURRENT_DESKTOP=labwc
    export XDG_SESSION_TYPE=wayland
    # labwc reads rc.xml/autostart from XDG_CONFIG_DIRS; set it explicitly
    # rather than depending on the default containing /etc/xdg.
    export XDG_CONFIG_DIRS="/etc/xdg''${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}"
    # Jellyfin Media Player is Qt; prefer native Wayland, fall back to XWayland.
    export QT_QPA_PLATFORM="wayland;xcb"
    exec ${lib.getExe cfg.compositor}
  '';
in
{
  options.services.tv = {
    enable = lib.mkEnableOption "the TV launcher session";

    user = lib.mkOption {
      type = lib.types.str;
      description = "User the TV session is auto-logged in as.";
    };

    apps = lib.mkOption {
      description = ''
        Launcher entries, in the order they appear. Each entry sets exactly
        one of {option}`url` (Chrome kiosk window) or {option}`command`.
      '';
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Label shown in the launcher.";
            };
            url = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Opened as an isolated Chrome kiosk window.";
            };
            command = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Command to run in the foreground instead of a browser window.";
            };
            userAgent = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = ''
                Override Chrome's User-Agent for this app. Needed for sites
                that gate a TV interface on it — YouTube's `/tv` leanback UI
                redirects away unless it sees a TV UA.
              '';
            };
          };
        }
      );
    };

    browser = lib.mkPackageOption pkgs "google-chrome" { };

    browserFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Flags passed to every web app window.";
      default = [
        "--kiosk"
        "--ozone-platform=wayland"
        "--no-first-run"
        "--no-default-browser-check"
        "--disable-features=TranslateUI"
        # A TV has no "user gesture" before playback starts.
        "--autoplay-policy=no-user-gesture-required"
        # VA-API hardware decode. Unprotected video (YouTube, Jellyfin web)
        # benefits; Widevine-protected streams decode in software regardless.
        # Verify what actually engaged at chrome://gpu.
        "--enable-features=VaapiVideoDecoder,VaapiVideoDecodeLinuxGL"
        "--ignore-gpu-blocklist"
      ];
    };

    compositor = lib.mkPackageOption pkgs "labwc" { };

    theme = lib.mkOption {
      type = lib.types.path;
      default = ./theme.rasi;
      description = "rofi theme used for the launcher.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = map (app: {
      assertion = (app.url == null) != (app.command == null);
      message = "services.tv.apps entry '${app.name}' must set exactly one of `url` or `command`.";
    }) cfg.apps;

    # Autologin straight into the session. `default_session` is set to the
    # same thing as `initial_session` so that quitting the compositor
    # relaunches it rather than dropping to a greeter no one can type into.
    services.greetd = {
      enable = true;
      settings = {
        initial_session = {
          command = "${session}";
          user = cfg.user;
        };
        default_session = {
          command = "${session}";
          user = cfg.user;
        };
      };
    };

    environment.etc."xdg/labwc/rc.xml".source = ./rc.xml;
    environment.etc."xdg/labwc/autostart".text = ''
      ${launcher}/bin/tv-launcher &
    '';

    # Target the AirPlay/DLNA receivers hang off, started by the launcher once
    # the Wayland socket exists.
    systemd.user.targets.tv-session = {
      description = "TV session (graphical, receivers may draw and play)";
    };

    environment.systemPackages = [
      launcher
      cfg.browser
      cfg.compositor
      pkgs.rofi
    ];

    hardware.graphics.enable = lib.mkDefault true;
    security.polkit.enable = true;
  };
}

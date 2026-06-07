{ config, lib, pkgs, ... }: 
let
  mod = "ALT";
in {
  
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;

    configType = "lua";

    settings = {

      monitor = {
      	_args = [ {
          output = "";
          mode = "preferred";
          position = "auto";
          scale = 1.57;
        } ];
      };

      config = {
        general = {
	        layout = "master";
          gaps_in = 3;
          gaps_out = 5;
          border_size = 2;
          "col.active_border" = {
            colors = [ "0xee33ccff" "0xee00ff99" ];
            angle = 45;
          };
          "col.inactive_border" = "0xaa595959";
          resize_on_border = false;
          allow_tearing = false;
	      };

        decoration = {
          rounding = 10;
          active_opacity = 1.0;
          inactive_opacity = 1.0;

          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
            color = "0xee1a1a1a";
          };

          blur = {
            enabled = true;
            size = 3;
            passes = 1;
            vibrancy = 0.1696;
          };
        };

        animations = {
          enabled = false;
          bezier = [
            "easeOutQuint, 0.23, 1, 0.32, 1"
            "easeInOutCubic, 0.65, 0.05, 0.36, 1"
            "linear, 0, 0, 1, 1"
            "almostLinear, 0.5, 0.5, 0.75, 1.0"
            "quick, 0.15, 0, 0.1, 1"
          ];
          animation = [
            "global, 1, 10, default"
            "border, 1, 5.39, easeOutQuint"
            "windows, 1, 4.79, easeOutQuint"
            "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
            "windowsOut, 1, 1.49, linear, popin 87%"
            "fadeIn, 1, 1.73, almostLinear"
            "fadeOut, 1, 1.46, almostLinear"
            "fade, 1, 3.03, quick"
            "layers, 1, 3.81, easeOutQuint"
            "layersIn, 1, 4, easeOutQuint, fade"
            "layersOut, 1, 1.5, linear, fade"
            "fadeLayersIn, 1, 1.79, almostLinear"
            "fadeLayersOut, 1, 1.39, almostLinear"
            "workspaces, 1, 1.94, almostLinear, fade"
            "workspacesIn, 1, 1.21, almostLinear, fade"
            "workspacesOut, 1, 1.94, almostLinear, fade"
          ];
        };

        misc = {
          force_default_wallpaper = -1;
          disable_hyprland_logo = false;
        };
        
        input = {
          kb_layout = "us";
          
          repeat_rate = 50;
          repeat_delay = 250; # ms pause
        };

        xwayland = {
          force_zero_scaling = true;
        };
      };

      bind = [
        { _args = [ "${mod} + SHIFT + Return" (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"ghostty\")") ]; }
        { _args = [ "${mod} + Return" (lib.generators.mkLuaInline "hl.dsp.layout(\"swapwithmaster\")") ]; }
        { _args = [ "${mod} + C" (lib.generators.mkLuaInline "hl.dsp.window.close()") ]; }
        
        { _args = [ "${mod} + K" (lib.generators.mkLuaInline "hl.dsp.window.cycle_next()") ]; }
        { _args = [ "${mod} + J" (lib.generators.mkLuaInline "hl.dsp.window.cycle_next({ next = false })") ]; }
    
        { _args = [ "${mod} + L" (lib.generators.mkLuaInline "hl.dsp.layout( \"mfact +0.05\" )") ]; }
        { _args = [ "${mod} + H" (lib.generators.mkLuaInline "hl.dsp.layout( \"mfact -0.05\" )") ]; }

        { _args = [ "${mod} + R" (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"rofi -show drun\")") ]; }

	      { _args = [ "${mod} + Q" (lib.generators.mkLuaInline "hl.dsp.exit()") ]; }
      ];
    };

    # Use extra config so that we don't need blocks of 9 for each bind
    extraConfig = ''
      local mod = "${mod}"

      for i = 1, 9 do
        local key = tostring(i)

        hl.bind(mod .. " + " .. key, hl.dsp.focus( { workspace = i } ))

        hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move( { workspace = i } ))
      end

      hl.on("hyprland.start", function ()
        hl.exec_cmd("waybar")
      end )

      -- Laptop multimedia keys for volume and LCD brightness
      hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
      hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
      hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
      hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
      hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
      hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

    '';
  };
}

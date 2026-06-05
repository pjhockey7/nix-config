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

      bind = [
        { _args = [ "${mod} + SHIFT + Return" (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"ghostty\")") ]; }
        { _args = [ "${mod} + C" (lib.generators.mkLuaInline "hl.dsp.window.close()") ]; }
        
	{ _args = [ "${mod} + Q" (lib.generators.mkLuaInline "hl.dsp.exit()") ]; }
      ];
    };

    extraConfig = ''
      local mod = "${mod}"

      for i = 1, 9 do
        local key = tostring(i)

        hl.bind(mod .. " + " .. key, hl.dsp.focus( { workspace = i } ))

        --hl.bind(mod .. " + SHIFT", key, hl.dsp.movetoworkspace(key))
      end
    '';
  };
}

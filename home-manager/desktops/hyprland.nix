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
	};
      };

      bind = [
        { _args = [ "${mod} + SHIFT + Return" (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"ghostty\")") ]; }
        { _args = [ "${mod} + Return" (lib.generators.mkLuaInline "hl.dsp.layout(\"swapwithmaster\")") ]; }
        { _args = [ "${mod} + C" (lib.generators.mkLuaInline "hl.dsp.window.close()") ]; }
        
	{ _args = [ "${mod} + J" (lib.generators.mkLuaInline "hl.dsp.focus( { direction = \"down\" } )") ]; }
	{ _args = [ "${mod} + K" (lib.generators.mkLuaInline "hl.dsp.focus( { direction = \"up\" } )") ]; }
	
	{ _args = [ "${mod} + L" (lib.generators.mkLuaInline "hl.dsp.layout( \"mfact +0.05\" )") ]; }
	{ _args = [ "${mod} + H" (lib.generators.mkLuaInline "hl.dsp.layout( \"mfact -0.05\" )") ]; }

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
    '';
  };
}

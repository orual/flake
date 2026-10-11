{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.profiles.games;
in {
  options.profiles.games = with lib; {
    enable = mkEnableOption "games profile";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # TODO(orual): currently broken in nixpkgs
      # minecraft
      #technic-launcher
      ckan
      # disable this, currently broken due to some kind of python thing
      # playonlinux
      moonlight
    ];

    xdg.configFile."openxr/1/active_runtime.json".text = ''
      {
         "file_format_version": "1.0.0",
          "runtime": {
          "VALVE_runtime_is_steamvr": true,
          "library_path": "${config.home.homeDirectory}/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrclient.so",
          "name": "SteamVR"
          }
      }
      '';
    xdg.configFile."openvr/openvrpaths.vrpath".text = let
        steam = "${config.xdg.dataHome}/Steam";
      in builtins.toJSON {
        version = 1;
        jsonid = "vrpathreg";

        external_drivers = null;
        config = [ "${steam}/config" ];

        log = [ "${steam}/logs" ];

        runtime = [
          "${config.home.homeDirectory}/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrccompositor-launcher.sh"
          #"${pkgs.xrizer}/lib/xrizer"
          # OR
          #"${pkgs.opencomposite}/lib/opencomposite"
          # OR (using nixpkgs-xr)
          # "${pkgs.vapor}/lib/VapoR"
        ];
      };
  };


}

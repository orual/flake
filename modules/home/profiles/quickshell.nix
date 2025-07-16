{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.profiles.quickshell;
in
{
  options.profiles.quickshell = with lib; {
    enable = mkEnableOption "quickshell profile";
  };

  config = lib.mkIf cfg.enable {
    programs.quickshell = {
      enable = true;
      activeConfig = null;
      systemd.enable = true;
      systemd.target = "niri-session.target";
    };

    home.packages = with pkgs; [
      quickshell
      qt6Packages.qt5compat
      libsForQt5.qt5.qtgraphicaleffects
      kdePackages.qtbase
      kdePackages.qtdeclarative
      material-symbols
      swww
      wallust
      gpu-screen-recorder
      cava
    ];
  };
}

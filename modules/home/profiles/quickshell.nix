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
    };

    home.packages = with pkgs; [
      quickshell
      qt6Packages.qt5compat
      libsforQt5.qt5.qgraphicaleffects
      kdePackages.qtbase
      kdePackages.qtdeclarative
    ];
  };
}

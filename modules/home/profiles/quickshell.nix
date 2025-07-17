{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.profiles.quickshell;
  homeDir = config.home.homeDirectory;
  quickshellDir = "${homeDir}/flake/modules/home/profiles/quickshell/qml";
  quickshellTarget = "${homeDir}/.config/quickshell";
  faceIconSource = "${homeDir}/flake/modules/home/profiles/Vin_Pride_pfp.png";
  faceIconTarget = "${homeDir}/.face.icon";
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
      #systemd.target = "graphical-session.target";
    };
    home.activation.symlinkQuickshellAndFaceIcon = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ln -sfn "${quickshellDir}" "${quickshellTarget}"
      ln -sfn "${faceIconSource}" "${faceIconTarget}"
    '';

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

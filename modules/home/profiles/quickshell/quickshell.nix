{ config, lib, pkgs, ... }:

let
  homeDir = config.home.homeDirectory;
  quickshellDir = "${homeDir}/nixos/home/quickshell/qml";
  quickshellTarget = "${homeDir}/.config/quickshell";
  faceIconSource = "${homeDir}/nixos/assets/profile.gif";
  faceIconTarget = "${homeDir}/.face.icon";
in {
  home.activation.symlinkQuickshellAndFaceIcon = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ln -sfn "${quickshellDir}" "${quickshellTarget}"
    ln -sfn "${faceIconSource}" "${faceIconTarget}"
  '';
}

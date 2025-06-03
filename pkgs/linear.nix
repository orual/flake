{
  lib,
  appimageTools,
  fetchurl,
}:

let
  version = "0.2.0";
  pname = "linear-linux";

  src = fetchurl {
    url = "https://github.com/kleo-dev/linear-linux/releases/download/v${version}/${pname}-${version}.AppImage";
    hash = "sha256-xppYSylEsfzzo89Ati1goC5BUpHTX2dDWgY3h3AaCCc=";
  };
  appimageContents = appimageTools.extract {
      inherit pname version src;
  };
  icon = ./Linear.png;
in
appimageTools.wrapType2 rec {
  inherit pname version src;

  extraInstallCommands = ''
      mv $out/bin/${pname} $out/bin/linear
      install -m 444 -D ${appimageContents}/${pname}.desktop $out/share/applications/linear.desktop
      install -m 444 -D ${icon} \
        $out/share/icons/hicolor/512x512/apps/linear.png
      substituteInPlace $out/share/applications/linear.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=linear' \
        --replace-fail 'Icon=${pname}' 'Icon=linear'
    '';

  meta = {
    mainProgram = "${pname}";
    description = "Project Management App";
    homepage = "https://github.com/kleo-dev/linear-linux";
    downloadPage = "https://github.com/kleo-dev/linear-linux/releases";
    license = lib.licenses.asl20;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
  };
}

{
  lib,
  appimageTools,
  fetchurl,
}:

let
  version = "0.2.0";
  pname = "hyperbeam";

  src = fetchurl {
    url = "https://cdn.hyperbeam.com/Hyperbeam-0.21.0.AppImage";
    hash = "sha256-7UYxtbqT65CAdngmrIq4290Ny8sCybt4FQgbUZHMd7I=";
  };
  appimageContents = appimageTools.extract {
      inherit pname version src;
  };
in
appimageTools.wrapType2 rec {
  inherit pname version src;

  extraInstallCommands = ''
      install -m 444 -D ${appimageContents}/${pname}.desktop $out/share/applications/hyperbeam.desktop
      install -m 444 -D ${appimageContents}/hyperbeam.png \
        $out/share/icons/hicolor/512x512/apps/hyperbeam.png
      substituteInPlace $out/share/applications/hyperbeam.desktop \
        --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=hyperbeam --in-process-gpu --no-sandbox' \
        --replace-fail 'Icon=${pname}' 'Icon=hyperbeam'
    '';

  meta = {
    mainProgram = "hyperbeam";
    description = "Shared web browser";
    homepage = "https://watch.hyperbeam.com";
    downloadPage = "https://watch.hyperbeam.com/download/";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
  };
}

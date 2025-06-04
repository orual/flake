{
  lib,
  appimageTools,
  fetchurl,
  pkgs,
}: let
  version = "4.0.732";
  pname = "beeper";

  src = fetchurl {
    url = "https://api.beeper.com/desktop/download/linux/x64/stable/com.automattic.beeper.desktop";
    hash = "sha256-8HcWEMrMpq+QCnkCf7Yn79fADy98KFqL/m1erXtM8XU=";
  };
  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
  appimageTools.wrapType2 rec {
    inherit pname version src;

    extraInstallCommands = ''

      install -m 444 -D ${appimageContents}/beepertexts.desktop $out/share/applications/beeper.desktop
      install -m 444 -D ${appimageContents}/usr/share/icons/hicolor/512x512/apps/beepertexts.png \
        $out/share/icons/hicolor/512x512/apps/beepertexts.png
      substituteInPlace $out/share/applications/beeper.desktop \
        --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=${pkgs.cage} -- beeper --no-sandbox'
    '';

    meta = {
      mainProgram = "${pname}";
      description = "Beeper multi-service text messaging";
      homepage = "https://www.beeper.com";
      downloadPage = "https://www.beeper.com/beta";
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      platforms = ["x86_64-linux"];
    };
  }

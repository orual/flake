{ stdenv, lib, fetchurl, makeDesktopItem, jre, libx11, libxext, libxcursor
, libxrandr, libxxf86vm, mesa, openal, pulseaudio }:

# let
#   desktopItem = stdenv.makeDesktopItem {
#     name = "technic-launcher";
#     exec = "technic-launcher";
#     icon = "technic-launcher";
#     comment = "Modded launcher for Minecraft, a sandbox-building game";
#     desktopName = "Technic Launcher";
#     categories = "Game;";
#   } in
stdenv.mkDerivation {
  name = "technic-launcher";
  src = fetchurl {
    url = "https://launcher.technicpack.net/launcher4/603/TechnicLauncher.jar";
    sha256 = "0x7b2s5f32lw4pwwb0b2wis16r053p5rmnkkrvm63490wbg8wfvm";
  };

  phases = "installPhase";

  installPhase = ''
    set -x
    mkdir -pv $out/bin
    cp -v $src $out/TechnicLauncher.jar
    cat > $out/bin/technic-launcher << EOF
    #!${stdenv.shell}
    # wrapper for minecraft
    export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${libx11}/lib/:${libxext}/lib/:${libxcursor}/lib/:${libxrandr}/lib/:${libxxf86vm}/lib/:${mesa}/lib/:${openal}/lib/
    ${pulseaudio}/bin/padsp ${jre}/bin/java -jar $out/TechnicLauncher.jar
    EOF
    chmod +x $out/bin/technic-launcher
  '';

  meta = {
    description = "Modded Minecraft launcher";
    homepage = "https://www.technicpack.net/";
    license = lib.licenses.unfree;
    platforms = lib.platforms.linux;
  };
}

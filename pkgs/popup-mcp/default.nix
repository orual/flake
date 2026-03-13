{
  fetchFromGitHub,
  lib,
  rustPlatform,
  pkg-config,
  makeWrapper,
  openssl,
  libGL,
  libxkbcommon,
  wayland,
  xorg,
  vulkan-loader,
}:
rustPlatform.buildRustPackage {
  pname = "popup-mcp";
  version = "0.4.0-unstable-2025-05-25";

  src = fetchFromGitHub {
    owner = "inanna-malick";
    repo = "popup-mcp";
    rev = "788227cf246b3ac827f06acc6590241b34dd483f";
    hash = "sha256-cWXEjs8E1FjUaVUkGGGqZ/KSJ++DBhz57CtcZJtAjh8=";
  };

  cargoHash = "sha256-Sg8JJ/F8HvPMI+VW6aBh7+zqt4BcBp7GrHmcv2ZZo18=";

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    openssl
    libGL
    libxkbcommon
    wayland
    vulkan-loader
    xorg.libX11
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr
    xorg.libxcb
  ];

  postInstall = ''
    wrapProgram $out/bin/popup \
      --prefix LD_LIBRARY_PATH : ${
      lib.makeLibraryPath [
        libGL
        libxkbcommon
        wayland
        vulkan-loader
        xorg.libX11
        xorg.libXcursor
        xorg.libXi
        xorg.libXrandr
        xorg.libxcb
      ]
    }
  '';

  meta = with lib; {
    description = "Native GUI popups via Model Context Protocol for AI assistants";
    homepage = "https://github.com/inanna-malick/popup-mcp";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "popup";
  };
}

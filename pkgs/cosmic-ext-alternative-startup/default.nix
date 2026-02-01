{
  fetchFromGitHub,
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "cosmic-ext-alternative-startup";
  version = "0.1.0-unstable-2024-11-02";

  src = fetchFromGitHub {
    owner = "drakulix";
    repo = "cosmic-ext-alternative-startup";
    rev = "main";
    hash = lib.fakeHash;
  };

  cargoHash = lib.fakeHash;

  meta = with lib; {
    description = "Alternative entry point for cosmic-session's compositor IPC interface";
    homepage = "https://github.com/drakulix/cosmic-ext-alternative-startup";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "cosmic-ext-alternative-startup";
  };
}

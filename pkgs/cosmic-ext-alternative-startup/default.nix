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
    rev = "8ceda00197c7ec0905cf1dccdc2d67d738e45417";
    hash = "sha256-0kqn3hZ58uQMl39XXF94yQS1EWmGIK45/JFTAigg/3M=";
  };

  cargoHash = "sha256-DeMkAG2iINGden0Up013M9mWDN4QHrF+FXoNqpGB+mg=";

  meta = with lib; {
    description = "Alternative entry point for cosmic-session's compositor IPC interface";
    homepage = "https://github.com/drakulix/cosmic-ext-alternative-startup";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "cosmic-ext-alternative-startup";
  };
}

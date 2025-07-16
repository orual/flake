{
  fetchFromGitHub,
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "discord-presence-lsp";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "xhyrom";
    repo = "zed-discord-presence";
    rev = "v${version}";
    sha256 = "sha256-6KpjJajibMY7pBR5XhZf2KPBkBMkdcYKutifNdF3Hko=";
  };

  cargoHash = "sha256-2hQHhrbUYKDtFX8ZiDpVYrd9/g6bCi9XL0VwKDWFE+s=";

  buildInputs = [
  ];

  preBuild = ''
    cd ./lsp
  '';

  installPhase = ''
    runHook preInstall
    install -m755  -D ../target/x86_64-unknown-linux-gnu/release/discord-presence-lsp $out/bin/discord-presence-lsp
    runHook postInstall
  '';

  # postInstall = ''
  #   wrapProgram $out/bin/nix-zed-extensions \
  #     --prefix PATH : ${
  #     lib.makeBinPath [
  #       fetch-cargo-vendor-util
  #       nix-prefetch-git
  #     ]
  #   }
  # '';

  meta = with lib; {
    description = "ZedDiscord Presence LSP";
    homepage = "https://github.com/xhyrom/zed-discord-presence";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}

{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs,
  pnpm_10,
  makeWrapper,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "social-cli";
  version = "0.1.0-unstable-2026-04-30";

  src = fetchFromGitHub {
    owner = "letta-ai";
    repo = "social-cli";
    rev = "dfd9bdefcf86ca1f27afa09e835305bcdbf2b23c";
    hash = "sha256-qe3oSDVoFIrrTQCLD55qsl0ie5XAlxQID6OLkcI0/Ko=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm_10
    pnpm_10.configHook
    makeWrapper
  ];

  pnpmDeps = pnpm_10.fetchDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 3;
    hash = "sha256-0fSeNnXuPT8T28O8upPkjS+3afAt1hzu2TFEslbhqX0=";
  };

  buildPhase = ''
    runHook preBuild
    pnpm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/social-cli
    cp -r dist node_modules package.json $out/lib/social-cli/

    makeWrapper ${lib.getExe nodejs} $out/bin/social-cli \
      --add-flags "$out/lib/social-cli/dist/cli.js"

    runHook postInstall
  '';

  meta = {
    description = "Agent-optimized social media CLI for Bluesky and X";
    homepage = "https://github.com/letta-ai/social-cli";
    license = lib.licenses.asl20;
    mainProgram = "social-cli";
    platforms = lib.platforms.unix;
  };
})

{
  lib,
  stdenv,
  fetchFromGitHub,
  bun,
  makeBinaryWrapper,
  autoPatchelfHook,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "claude-code-modes";
  version = "0.2.3-orual";

  src = fetchFromGitHub {
    owner = "orual";
    repo = "claude-code-modes";
    rev = "0e69bf878ae92f1f6f1c3b7219bb574d6a4f8025";
    hash = "sha256-niHSCtv2Ck5Hdo8tYh6vq/2COYP9nG6eKe2nTbf3d2g=";
  };

  nativeBuildInputs =
    [
      bun
      makeBinaryWrapper
    ]
    ++ lib.optionals stdenv.hostPlatform.isElf [autoPatchelfHook];

  dontConfigure = true;
  dontStrip = true;

  buildPhase = ''
    runHook preBuild

    # generate the embedded prompts TypeScript file
    bun scripts/generate-prompts.ts

    # compile to a standalone binary
    bun build src/cli.ts --compile --outfile claude-mode

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 claude-mode $out/bin/claude-mode

    runHook postInstall
  '';

  meta = {
    description = "Behaviorally-tuned system prompts for Claude Code";
    homepage = "https://github.com/orual/claude-code-modes";
    license = lib.licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "claude-mode";
  };
})

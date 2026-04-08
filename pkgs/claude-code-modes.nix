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
  version = "0.2.3";

  src = fetchFromGitHub {
    owner = "nklisch";
    repo = "claude-code-modes";
    tag = "v${finalAttrs.version}";
    hash = "sha256-AcGpil1BGg1nyzjLQvWfZss9jyyWBy+GubIZ2hSdn8g=";
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
    homepage = "https://github.com/nklisch/claude-code-modes";
    license = lib.licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "claude-mode";
  };
})

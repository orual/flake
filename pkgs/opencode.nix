{
  lib,
  fetchFromGitHub,
  buildGoModule,
}:
buildGoModule (finalAttrs: {
  pname = "opencode";
  version = "0.3.61";

  src = fetchFromGitHub {
    owner = "sst";
    repo = "opencode";
    tag = "v${finalAttrs.version}";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  vendorHash = "";

  checkFlags = let
    skippedTests = [
      # permission denied
      "TestBashTool_Run"
      "TestSourcegraphTool_Run"
      "TestLsTool_Run"
    ];
  in ["-skip=^${lib.concatStringsSep "$|^" skippedTests}$"];

  meta = {
    description = "Powerful terminal-based AI assistant providing intelligent coding assistance";
    homepage = "https://github.com/sst/opencode";
    mainProgram = "opencode";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      zestsystem
    ];
  };
})

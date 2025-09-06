{
  lib,
  buildNpmPackage,
  fetchzip,
  nodejs_20,
}:
buildNpmPackage rec {
  pname = "claude-code-acp";
  version = "0.2.4";

  nodejs = nodejs_20; # required for sandboxed Nix builds on Darwin

  src = fetchzip {
    url = "https://registry.npmjs.org/@zed-industries/claude-code-acp/-/claude-code-acp-${version}.tgz";
    hash = "sha256-37+jM59bnOWtL/+05V4+kWjCQVgTA8sjj7TMniNT9nE=";
  };

  npmDepsHash = "sha256-N85g0tWWyx2RZ9t9/MwBja18xAP6+IDg+SkOIeFeeUY=";

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;

  AUTHORIZED = "1";

  # `claude-code` tries to auto-update by default, this disables that functionality.
  # https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview#environment-variables
  postInstall = ''
    wrapProgram $out/bin/claude-code-acp \
      --set DISABLE_AUTOUPDATER 1
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "An agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster";
    homepage = "https://github.com/zed-industries/claude-code-acp";
    downloadPage = "https://www.npmjs.com/package/@zed-industries/claude-code-acp";
    license = lib.licenses.asl20;
    mainProgram = "claude-code-acp";
  };
}

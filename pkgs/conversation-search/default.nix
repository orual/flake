{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_20,
  makeWrapper,
}:
buildNpmPackage rec {
  pname = "conversation-search";
  version = "unstable-2025-11-02";

  nodejs = nodejs_20;

  src = fetchFromGitHub {
    owner = "obra";
    repo = "superpowers-skills";
    rev = "main"; # or a specific commit hash
    hash = "sha256-6YjesAgBa/q9ClxFUZLOfLhK44/thaeLh9J1mNZNokA=";
  };

  sourceRoot = "${src.name}/skills/collaboration/remembering-conversations/tool";

  npmDepsHash = "sha256-1qDBTJkKFlxUVWsff3eV+CPoPCcjRHeJI9mJd79P9Xk=";

  nativeBuildInputs = [makeWrapper];

  dontNpmBuild = true;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
    patchShebangs .
  '';

  postInstall = ''
    mkdir -p $out/bin

    # Wrap scripts to run from correct directory
    makeWrapper $out/lib/node_modules/conversation-search/index-conversations \
      $out/bin/index-conversations \
      --run "cd $out/lib/node_modules/conversation-search"

    makeWrapper $out/lib/node_modules/conversation-search/search-conversations \
      $out/bin/search-conversations \
      --run "cd $out/lib/node_modules/conversation-search"

    makeWrapper $out/lib/node_modules/conversation-search/install-hook \
      $out/bin/install-hook \
      --run "cd $out/lib/node_modules/conversation-search"
  '';

  meta = {
    description = "Search and index Claude Code conversation history";
    homepage = "https://github.com/obra/superpowers-skills";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "search-conversations";
  };
}

final: prev: {
  ckan-1_29 = prev.callPackage ./ckan-1_29.nix {};
  humility = prev.callPackage ./humility.nix {};
  prometheusMdns = prev.callPackage ./prometheus-mdns.nix {};
  technic-launcher = prev.callPackage ./technic-launcher.nix {};
  xfel = prev.callPackage ./xfel.nix {};
  cursor-editor = prev.callPackage ./cursorsh.nix {};
  bitwig-studio = prev.callPackage ./bitwig-studio.nix {};
  esp-rs-nix = prev.callPackage ./esp-rs/default.nix {};
  linear = prev.callPackage ./linear.nix {};
  hyperbeam-watch-party = prev.callPackage ./hyperbeam.nix {};
  beeper-beta = prev.callPackage ./beeper-beta.nix {};
  zed-prerelease = prev.callPackage ./zed-editor {};
  discord-presence-lsp = prev.callPackage ./discord-presence-lsp {};
  cargotom = prev.callPackage ./cargotom {};
  claude-code-latest = prev.callPackage ./claude-code {};
  claude-code-acp = prev.callPackage ./claude-code-acp {};
  opencode-latest = prev.callPackage ./opencode.nix {};
  glasgow-latest = prev.callPackage ./glasgow-latest.nix {};
  #minipro-git = prev.callPackage ./minipro-git { };
  stm32cubeprog = prev.callPackage ./stm32cubeprogrammer.nix {};
  obsidian-x11 = prev.callPackage ./obsidian-x11.nix {};
  conversation-search = prev.callPackage ./conversation-search {};
}

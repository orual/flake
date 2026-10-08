{pkgs, config, ...}: let
  profileBin = "${config.home.profileDirectory}/bin";

  # The profile's desktop entries with Exec/TryExec pointing at the profile's bin.
  # The profile link rather than a store path, so entries don't change every generation.
  entries = pkgs.runCommand "frame-desktop-entries" { } ''
    mkdir -p $out

    for src in ${config.home.path}/share/applications/*.desktop; do
      awk -v bin=${config.home.path}/bin -v profile=${profileBin} '
        match($0, /^(TryExec|Exec)=/) {
          key = substr($0, 1, RLENGTH)
          rest = substr($0, RLENGTH + 1)
          split(rest, words, " ")
          cmd = words[1]

          if (cmd !~ /// && system("test -e "" bin "/" cmd """) == 0)
            $0 = key profile "/" cmd substr(rest, length(cmd) + 1)
        }
        { print }
      ' "$src" > "$out/$(basename "$src")"
    done
  '';
in {
  profiles = {
    desktop = {
      enable = true;
      niri.enable = true;
      niri.enableTablet = true;
      niri.noctaliaShell = true;
    };
    devtools = {
      enable = true;
      enablePython = true;
    };
    noctalia.enable = true;
    #terminal.font.family = "TX-02";
  };

  home.packages = with pkgs; [
    # not trying to build ESP32-C3 on this machine, so global clang is fine...
    clang
    # global pkgconfig too
    pkg-config
    yubioath-flutter
    atuin-desktop
  ];

  programs.frametop.enable = true;

  home.username = "steamos";
  home.homeDirectory = "/home/steamos";


  services = {
    gpg-agent = {
      enable = true;
      # pinentryFlavor = "gnome3";
    };
  };

  programs.steamos-etc = {
    enable = true;
    # Hold the user session until /nix is mounted.
    waitForNix = true;
    # /run/opengl-driver for Nix-built GUI apps.
    gpuDrivers = true;
  };

  targets.genericLinux.enable = true;  # enables some options to make home manager work better on non-nixos setups

  programs.home-manager.enable = true; # standalone installs need this to get the home-manager cli





  # Linked file by file (recursive) so Steam's own shortcuts in there stay.
  xdg.dataFile."applications" = {
    source = entries;
    recursive = true;
  };

  programs.steamos-etc.services.tailscaled = {
    Unit = {
      Description = "Tailscale node agent";
      Documentation = "https://tailscale.com/docs/";
      Wants = [ "network-pre.target" ];
      After = [
        "network-pre.target"
        "NetworkManager.service"
        "systemd-resolved.service"
      ];
    };

    Service = {
      # 41641 is the default port the nixos tailscale module uses
      ExecStart = "${pkgs.tailscale}/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=41641";
      ExecStopPost = "${pkgs.tailscale}/bin/tailscaled --cleanup";
      Restart = "on-failure";
      Type = "notify";

      RuntimeDirectory = "tailscale";
      RuntimeDirectoryMode = "0755";
      StateDirectory = "tailscale";
      StateDirectoryMode = "0700";
      CacheDirectory = "tailscale";
      CacheDirectoryMode = "0750";
    };

    Install.WantedBy = [ "multi-user.target" ];
  };
}

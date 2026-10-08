{pkgs, ...}: {
  profiles = {
    games.enable = true;
    desktop = {
      enable = true;
      #gnome3.enable = true;
      niri.enable = true;
      niri.noctaliaShell = true;
      #niri.cosmicOnNiri = true;
    };
    k8s.enable = true;
    devtools = {
      enable = true;
      enablePython = true;
    };
    noctalia.enable = true;
  };

  home.packages = with pkgs; [
    # not trying to build ESP32-C3 on this machine, so global clang is fine...
    clang
    # global pkgconfig too
    pkg-config
    lm_sensors

    #hyperbeam-watch-party
    wechat-uos
    yubioath-flutter
    protonup-qt
    bitwig-studio
    droidcam

    systemctl-tui
    vmware-workstation
    remmina
    atuin-desktop
    claude-desktop
    social-cli
    losslesscut-bin
  ];

  services = {
    gpg-agent = {
      enable = true;
      # pinentryFlavor = "gnome3";
    };
    udiskie = {
      enable = true;
      settings = {
        # workaround for
        # https://github.com/nix-community/home-manager/issues/632
        program_options = {
          # replace with your favorite file manager
          file_manager = "${pkgs.nemo-with-extensions}/bin/nemo";
        };
      };
    };
    meridian = {
      enable = true;
      settings = {
        port = 3456;
        host = "127.0.0.1";
        passthrough = true;
        # defaultAgent = "opencode";
        # sonnetModel = "sonnet";
      };
      # Extra env vars not covered by settings
      # environment = {
      #   MERIDIAN_MAX_CONCURRENT = "20";
      # };
    };
  };
}

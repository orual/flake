{pkgs, ...}: {
  profiles = {
    games.enable = true;
    desktop = {
      enable = true;
      gnome3.enable = true;
      niri.enable = true;
    };
    k8s.enable = true;
    devtools = {
      enable = true;
      enablePython = true;
    };
    waybar.enable = true;
  };

  home.packages = with pkgs; [
    # not trying to build ESP32-C3 on this machine, so global clang is fine...
    clang
    # global pkgconfig too
    pkg-config
    lm_sensors

    hyperbeam-watch-party
    wechat-uos
    yubioath-flutter
    protonup-qt
    bitwig-studio

    systemctl-tui
    vmware-workstation
    remmina
    atuin-desktop
    claude-code-acp
    #claude-desktop
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
  };
}

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
    conky

    hyperbeam-watch-party
    wechat-uos
    yubioath-flutter
    protonup-qt
    bitwig-studio

    systemctl-tui
    vmware-workstation
    remmina
    atuin-desktop
    claude-desktop
  ];

  services = {
    gpg-agent = {
      enable = true;
      # pinentryFlavor = "gnome3";
    };
  };
}

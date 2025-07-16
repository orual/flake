{ pkgs, ... }:

{
  profiles = {
    desktop = {
      enable = true;
      gnome3.enable = true;
      niri.enable = true;
    };
    devtools = {
      enable = true;
      enablePython = true;
    };
    waybar.enable = true;
    quickshell.enable = true;
    #terminal.font.family = "TX-02";
  };

  home.packages = with pkgs; [
    # not trying to build ESP32-C3 on this machine, so global clang is fine...
    clang
    # global pkgconfig too
    pkg-config
    qemu
    screen
    yubioath-flutter
    protonup-qt
    bitwig-studio
    atuin-desktop
  ];

  #programs.gdb.dashboard.enable = false;

  services = {
    gpg-agent = {
      enable = true;
      # pinentryFlavor = "gnome3";
    };
  };
}

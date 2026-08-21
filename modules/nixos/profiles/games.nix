{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.profiles.games;
in {
  options.profiles.games = with lib; {
    enable = mkEnableOption "games profile";
  };


  config = lib.mkIf cfg.enable {
    # some steam games need 32-bit driver support
    services.pulseaudio.support32Bit = true;
    hardware = {
      graphics = {
        extraPackages32 = with pkgs.pkgsi686Linux; [libva];
        enable32Bit = true;
      };
      enableRedistributableFirmware = true;
      wirelessRegulatoryDatabase = true;
    };

    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
    };

    # Steam controller
    hardware.steam-hardware.enable = true;

    programs.gamescope = {
      enable = true;
      enableWsi = true;
      capSysNice = false;
    };
    # Steam
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      extraPackages = with pkgs; [
        sodi-x-run
        mangohud
        gamescope
        xwayland-run
        libXcursor
        hidapi
            libXi
            libXinerama
            libXScrnSaver
            libpng
            libpulseaudio
            libvorbis
            stdenv.cc.cc.lib # Provides libstdc++.so.6
            libkrb5
            keyutils
      ];
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
      extest.enable = true;
      # fix steam input mouse cursor stuff
      package = pkgs.steam.override {
          # extraProfile = ''export LD_PRELOAD=${pkgs.extest}/lib/libextest.so:$LD_PRELOAD'';
          extraArgs = ''-pipewire -xcb'';
      };
    };

    boot.kernelPatches = [
      {
        name = "amdgpu-ignore-ctx-privileges";
        patch = pkgs.fetchpatch {
          name = "cap_sys_nice_begone.patch";
          url = "https://github.com/Frogging-Family/community-patches/raw/master/linux61-tkg/cap_sys_nice_begone.mypatch";
          hash = "sha256-Y3a0+x2xvHsfLax/uwycdJf3xLxvVfkfDVqjkxNaYEo=";
        };
      }
    ];

    boot.extraModprobeConfig = ''
      options cfg80211 ieee80211_regdom=CA
    '';

  };
}

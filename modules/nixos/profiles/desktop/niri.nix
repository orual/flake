{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.profiles.desktop;
in
  with lib; {
    options.profiles.desktop.niri = {
      enable = mkEnableOption "niri profile";
    };

    config = mkIf cfg.niri.enable {
      profiles.desktop.enable = mkDefault true;

      services = {
        displayManager = {
          defaultSession = mkForce "niri";
          gdm = {
            enable = mkDefault true;
            wayland = mkDefault true;
          };
        };
      };
      xdg = {
        portal = {
          enable = true;
          xdgOpenUsePortal = true;
          extraPortals = with pkgs; [
            xdg-desktop-portal-gnome
            xdg-desktop-portal-gtk
          ];
        };
      };

      nixpkgs.overlays = [
        
      ];
      programs = {
        firefox = {
          package = mkForce pkgs.firefox-wayland;
          nativeMessagingHosts.packages = with pkgs; [tridactyl-native firefoxpwa];
        };
        niri.enable = true;

        niri.package = pkgs.niri-unstable;
      };
      environment.variables.NIXOS_OZONE_WL = "1";
      environment.variables.ELECTRON_OZONE_PLATFORM_HINT = "auto";
      environment.etc = {
        "1password/custom_allowed_browsers" = {
          text = ''
            .zen-twilight-wrapped
          ''; # or just "zen" if you use unwrapped package
          mode = "0755";
        };
      };

      ### gnome-keyring #########################################################
      # enable the Gnome keyring
      services.gnome.gnome-keyring.enable = mkDefault true;
      # enable gnome keyring unlock on login
      security.pam.services = {
        login.enableGnomeKeyring = mkDefault true;
      };

      services.gnome = {
        core-apps.enable = true;
      };
    };
  }

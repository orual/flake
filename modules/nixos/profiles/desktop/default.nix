# Profile for desktop machines (i.e. not servers).
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.profiles.desktop;
in {
  imports = [./gnome3.nix ./kde.nix ./niri.nix];

  options.profiles.desktop = with lib; {
    enable = mkEnableOption "Profile for desktop machines (i.e. not servers)";
  };

  config = lib.mkIf cfg.enable {
    # Use latest kernel by default.
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

    ### pipewire ###
    # Use PipeWire as the system audio/video bus
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      jack.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
      socketActivation = true;
      extraConfig = {
        pipewire = {
          "10-clock-rate" = {
            "context.properties" = {
              "default.clock.rate" = 96000;
              "default.clock.allowed-rates" = [44100 48000 88200 96000];
            };
          };
        };
        # jack = {
        #   "20-latency-control" = {
        #       "jack.properties" = {
        #         "node.force-quantum" = "64";
        #       };
        #     };
        # };
      };
    };

    ### services ###

    services = {
      # Enable the X11 windowing system.
      xserver = with lib; {
        enable = mkDefault true;

        # Configure keymap in X11
        xkb = {
          layout = mkDefault "us";
          variant = mkDefault "";
        };
      };

      # Enable CUPS to print documents.
      printing.enable = lib.mkDefault true;
    };

    ### hardware ###
    hardware = {
      bluetooth.enable = lib.mkDefault true;
      ergodox.enable = lib.mkDefault true;
    };

    ### programs ###
    programs = {
      # Enable 1password and 1password-gui
      _1password.enable = true;
      _1password-gui = {
        enable = true;
        polkitPolicyOwners = ["orual"];
      };

      firefox.enable = true;
    };

    stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine.yaml";
    stylix.enable = true;
    stylix.polarity = "dark";

    stylix.fonts = {
      serif = {
        package = pkgs.ibm-plex;
        name = "IBM Plex";
      };

      sansSerif = {
        package = pkgs.ibm-plex;
        name = "IBM Plex Sans";
      };

      monospace = {
        package = pkgs.nerd-fonts.blex-mono;
        name = "BlexMono Nerd Font";
      };

      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };
  };
}

# Profile for desktop machines (i.e. not servers).
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.profiles.desktop;
  platform = pkgs.stdenv.hostPlatform;
in {
  imports = [
    ./gnome3.nix
    ./kde.nix
    ./niri.nix
  ];

  options.profiles.desktop = with lib; {
    enable = mkEnableOption "Profile for desktop machines (i.e. not servers)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; let
      unfreePkgs = [
        #slack
        (vesktop.override {withSystemVencord = false;})
        signal-desktop
        obsidian
        beeper
        beeper-bridge-manager
        parsec-bin
      ];
      x86Pkgs =
        if platform.isx86_64
        then [
          zoom-us
          spotify
          davinci-resolve
        ]
        else [];
    in (
      [
        ### images, media, etc ###
        kdePackages.ark
        darktable
        inkscape
        # broken due to https://github.com/NixOS/nixpkgs/issues/188525
        # llpp # fast & lightweight PDF pager
        krita # like the GNU Image Manipulation Photoshop, but more good
        gimp
        syncplay
        vlc
        mpv
        #plex-desktop
        ghostscriptX

        ### stuff ###
        bitwarden-desktop
        bitwarden-cli
        chromium
        deluge-gtk
        zulip
        libreoffice
        zmk-studio
      ]
      ++ unfreePkgs
      ++ x86Pkgs
    );
    #############################################################################
    ## Programs                                                                 #
    #############################################################################
    programs = {
      firefox = {
        enable = true;
        nativeMessagingHosts = [
          pkgs.tridactyl-native
        ];
        configPath = "${config.xdg.configHome}/mozilla/firefox";
      };
      ghostty.enable = true;
      bitwarden.enableSshAgent = lib.mkDefault true;
      keychain = {
        enable = true;
        enableXsessionIntegration = true;
        keys = ["id_ed25519"];
      };
      obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [
          droidcam-obs
          obs-markdown
          obs-pipewire-audio-capture
          obs-multi-rtmp
          obs-vaapi
          obs-vkcapture
          obs-backgroundremoval
          obs-aitum-multistream
        ];
      };

        voxtype = {
          enable = true;
          #engine = "parakeet";
          package = inputs.voxtype.packages.${platform.system}.vulkan;
          model.name = "base.en";
          #model.path = "${config.home.homeDirectory}.local/share/voxtype/models/parakeet-tdt-0.6b-v3";
          service.enable = true;
          settings = {
            hotkey.enabled = false;
            whisper.language = "en";
          };
        };
    };

    #############################################################################
    ## Services                                                                 #
    #############################################################################
    services = {
      gpg-agent.enable = true;
    };

    systemd.user.services.bitwarden = {
      Unit = {
        Description = "Bitwarden";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Install.WantedBy = ["graphical-session.target"];
      Service = {
        ExecStart = "${pkgs.bitwarden-desktop}/bin/bitwarden --autostart";
        Restart = "on-failure";
      };
    };

    stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine.yaml";
    stylix.enable = true;
    stylix.polarity = "dark";
    stylix.image = ./abstract-colorful-5k-wallpaper-5120x3200_577747-mm-90.jpg;
    stylix.targets.firefox.enable = false;
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
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
  };
}

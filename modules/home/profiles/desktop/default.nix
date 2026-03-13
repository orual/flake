# Profile for desktop machines (i.e. not servers).
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.profiles.desktop;
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
        slack
        (vesktop.override {withSystemVencord = false;})
        signal-desktop
        zoom-us
        spotify
        obsidian-x11
        beeper
        beeper-bridge-manager
        davinci-resolve
      ];
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
        #plex-desktop
        ghostscriptX
        losslesscut-bin

        ### stuff ###
        chromium
        #torrential
        zulip
        libreoffice-fresh
      ]
      ++ unfreePkgs
    );
    #############################################################################
    ## Programs                                                                 #
    #############################################################################
    programs = {
      firefox = {
        enable = true;
        nativeMessagingHosts = [
          pkgs.tridactyl-native
          pkgs.firefoxpwa
        ];
      };
      ghostty.enable = true;
      _1password-gui.enableSshAgent = lib.mkDefault true;
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
    };

    #############################################################################
    ## Services                                                                 #
    #############################################################################
    services = {
      gpg-agent.enable = true;
    };

    # 1password autostart
    systemd.user.services."1password" = {
      Unit = {
        Description = "1Password";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Install.WantedBy = ["graphical-session.target"];
      Service = {
        ExecStart = "${pkgs._1password-gui}/bin/1password --silent";
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

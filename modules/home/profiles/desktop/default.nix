# Profile for desktop machines (i.e. not servers).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.profiles.desktop;
in
{
  imports = [
    ./gnome3.nix
    ./kde.nix
    ./niri.nix
  ];

  options.profiles.desktop = with lib; {
    enable = mkEnableOption "Profile for desktop machines (i.e. not servers)";
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      let
        unfreePkgs = [
          slack
          (vesktop.override { withSystemVencord = false; })
          signal-desktop-bin
          zoom-us
          spotify
          (obsidian.override { })
          beeper-beta
        ];
      in
      (
        [
          ### images, media, etc ###
          kdePackages.ark
          darktable
          inkscape
          obs-studio
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
          torrential
          zulip
        ]
        ++ unfreePkgs
      );
    #############################################################################
    ## Programs                                                                 #
    #############################################################################
    programs = {
      firefox.enable = true;
      ghostty.enable = true;
      _1password-gui.enableSshAgent = lib.mkDefault true;
      keychain = {
        enable = true;
        enableXsessionIntegration = true;
        keys = [ "id_ed25519" ];
      };
    };

    #############################################################################
    ## Services                                                                 #
    #############################################################################
    services = {
      gpg-agent.enable = true;
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
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };
  };
}

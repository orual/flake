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
    };

    # Steam controller
    hardware.steam-hardware.enable = true;
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
      ];
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
      package = let
        x-wrapped = steam:
          pkgs.runCommand "x-run-steam"
          {
            inherit (steam) passthru meta;
          }
          ''
            cp -r ${steam} $out

            # $out/share is a symlink to ${steam}/share
            # but since we need to edit its internals, we need to expand it to a real directory
            # that can be edited

            # first we need to make sure we can remove it
            chmod -R +w $out

            # then remove, recreate, and populate it
            rm $out/share
            mkdir $out/share
            cp -r ${steam}/share/* $out/share/

            # and of course, make sure we can edit the desktop file again
            chmod -R +w $out

            sed -i 's/Exec=steam/Exec=x-run steam/g' $out/share/applications/steam.desktop
          '';
      in
        x-wrapped pkgs.steam
        // {
          override = f: x-wrapped (pkgs.steam.override f);
        };
    };
  };
}

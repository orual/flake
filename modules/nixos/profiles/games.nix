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
      
    };
    nixpkgs.overlays = [
      (final: prev: {
        steam = prev.steam.override ({extraPkgs ? pkgs': [], ...}: {
          extraPkgs = pkgs':
            (extraPkgs pkgs')
            ++ (with pkgs'; [
              libgdiplus
              libxkbcommon
              mesa
              wayland
              dconf
              gamescope
              mangohud
              extest
              #sodi-x-run
              #xwayland-run
            ]);
        });
      })
      # ( final: prev: {
      #   # example = prev.example.overrideAttrs (oldAttrs: rec {
      #   # ...
      #   # });
      #   sodi-x-run-env = let
      #     wl-copy = lib.getExe' final.wl-clipboard "wl-copy";
      #     wl-paste = lib.getExe' final.wl-clipboard "wl-paste";
      #     xclip = lib.getExe final.xclip;
      #     clipnotify = lib.getExe final.clipnotify;
      #     metacity = lib.getExe final.metacity;
      #   in
      #     # Here, we use xclip over xsel because it supports binary data.
      #     # Additionally, we sha256sum that binary data so no shell fuckery happens to null bytes.
      #     # Doing so ensures we don't overwrite image/png data, among others.
      #     # See also: https://gaysex.cloud/notes/9v1o3sc3q66f0mrr
      #     final.writeShellScriptBin "x-run-env" ''

      #       primary-wl-to-x () {
      #         while read; do
      #           if [[ "$(${wl-paste} --primary --no-newline | sha256sum)" != "$(${xclip} -selection primary -out | sha256sum)" ]]; then
      #             echo "syncing primary wl->x"
      #             ${wl-paste} --primary --no-newline | ${xclip} -selection primary -in
      #           fi
      #         done < <(${wl-paste} --primary --watch echo)
      #       }

      #       primary-x-to-wl () {
      #         while ${clipnotify} -s primary; do
      #           if [[ "$(${wl-paste} --primary --no-newline | sha256sum)" != "$(${xclip} -selection primary -out | sha256sum)" ]]; then
      #             echo "syncing primary x->wl"
      #             ${xclip} -selection primary -out | ${wl-copy} --primary
      #           fi
      #         done
      #       }

      #       clipboard-wl-to-x () {
      #         while read; do
      #           if [[ "$(${wl-paste} --no-newline | sha256sum)" != "$(${xclip} -selection clipboard -out | sha256sum)" ]]; then
      #             echo "syncing clipboard wl->x"
      #             ${wl-paste} --no-newline | ${xclip} -selection clipboard -in
      #           fi
      #         done < <(${wl-paste} --watch echo)
      #       }

      #       clipboard-x-to-wl () {
      #         while ${clipnotify} -s clipboard; do
      #           if [[ "$(${wl-paste} --no-newline | sha256sum)" != "$(${xclip} -selection clipboard -out | sha256sum)" ]]; then
      #             echo "syncing clipboard x->wl"
      #             ${xclip} -selection clipboard -out | ${wl-copy}
      #           fi
      #         done
      #       }

      #       clipboard-wl-to-x &
      #       clipboard-x-to-wl &
      #       primary-wl-to-x &
      #       primary-x-to-wl &

      #       ${metacity} &

      #       "$@"
      #     '';
      #   sodi-x-run = final.writeShellScriptBin "x-run" ''
      #     ${lib.getExe final.xwayland-run} -- ${lib.getExe final.sodi-x-run-env} "$@"
      #   '';
      # })
    ];
  };
}

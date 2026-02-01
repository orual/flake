{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.profiles.desktop;

  # COSMIC on niri session startup script
  startCosmicNiri = pkgs.writeShellScriptBin "start-cosmic-ext-niri" ''
    set -e

    # Reset failed systemd units from previous sessions
    if command -v systemctl >/dev/null; then
      for unit in $(systemctl --user --no-legend --state=failed --plain list-units | cut -f1 -d' '); do
        partof="$(systemctl --user show -p PartOf --value "$unit")"
        for target in cosmic-session.target graphical-session.target; do
          if [ "$partof" = "$target" ]; then
            systemctl --user reset-failed "$unit"
            break
          fi
        done
      done
    fi

    # Source login shell for environment variables
    if [ -n "''${SHELL}" ]; then
      if [ "$1" != "--in-login-shell" ]; then
        exec bash -c 'exec -l "''${SHELL}" -c "$1 --in-login-shell"' _ "$0"
      fi
    fi

    export XDG_CURRENT_DESKTOP="''${XDG_CURRENT_DESKTOP:=niri}"
    export XDG_SESSION_TYPE="''${XDG_SESSION_TYPE:=wayland}"
    export XCURSOR_THEME="''${XCURSOR_THEME:=Cosmic}"
    export _JAVA_AWT_WM_NONREPARENTING=1
    export GDK_BACKEND=wayland,x11
    export MOZ_ENABLE_WAYLAND=1
    export QT_QPA_PLATFORM="wayland;xcb"
    export QT_AUTO_SCREEN_SCALE_FACTOR=1
    export QT_ENABLE_HIGHDPI_SCALING=1

    if command -v systemctl >/dev/null; then
      systemctl --user import-environment XDG_SESSION_TYPE XDG_CURRENT_DESKTOP
    fi

    # Run cosmic-session with niri
    if [[ -z "''${DBUS_SESSION_BUS_ADDRESS}" ]]; then
      exec ${pkgs.dbus}/bin/dbus-run-session -- ${pkgs.cosmic-session}/bin/cosmic-session niri
    else
      exec ${pkgs.cosmic-session}/bin/cosmic-session niri
    fi
  '';

  # Desktop session file for display managers
  cosmicNiriSession = pkgs.writeTextFile {
    name = "cosmic-ext-niri-session";
    destination = "/share/wayland-sessions/cosmic-ext-niri.desktop";
    text = ''
      [Desktop Entry]
      Name=COSMIC on niri
      Comment=This session logs you into the COSMIC desktop on niri
      Exec=${startCosmicNiri}/bin/start-cosmic-ext-niri
      Type=Application
      DesktopNames=niri
    '';
    passthru.providedSessions = ["cosmic-ext-niri"];
  };
in
  with lib; {
    options.profiles.desktop.niri = {
      enable = mkEnableOption "niri profile";
      cosmicOnNiri = mkEnableOption "COSMIC desktop components running on niri compositor";
    };

    config = mkMerge [
      (mkIf cfg.niri.enable {
        profiles.desktop.enable = mkDefault true;

        services = {
          displayManager = {
            defaultSession = mkForce "niri";
            cosmic-greeter.enable = mkDefault true;
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

        environment.systemPackages = with pkgs; [
          xwayland-run
          sodi-x-run
          xwlsat-run
          libnotify
          xwayland-satellite
          cage
          wl-clipboard
          wayland-utils
          libsecret
          gamescope
        ];

        nixpkgs.overlays = [
          (final: prev: {
            sodi-x-run-env = let
              wl-copy = lib.getExe' final.wl-clipboard "wl-copy";
              wl-paste = lib.getExe' final.wl-clipboard "wl-paste";
              xclip = lib.getExe final.xclip;
              clipnotify = lib.getExe final.clipnotify;
              metacity = lib.getExe final.metacity;
            in
              # Here, we use xclip over xsel because it supports binary data.
              # Additionally, we sha256sum that binary data so no shell fuckery happens to null bytes.
              # Doing so ensures we don't overwrite image/png data, among others.
              # See also: https://gaysex.cloud/notes/9v1o3sc3q66f0mrr
              final.writeShellScriptBin "x-run-env" ''

                primary-wl-to-x () {
                  while read; do
                    if [[ "$(${wl-paste} --primary --no-newline | sha256sum)" != "$(${xclip} -selection primary -out | sha256sum)" ]]; then
                      echo "syncing primary wl->x"
                      ${wl-paste} --primary --no-newline | ${xclip} -selection primary -in
                    fi
                  done < <(${wl-paste} --primary --watch echo)
                }

                primary-x-to-wl () {
                  while ${clipnotify} -s primary; do
                    if [[ "$(${wl-paste} --primary --no-newline | sha256sum)" != "$(${xclip} -selection primary -out | sha256sum)" ]]; then
                      echo "syncing primary x->wl"
                      ${xclip} -selection primary -out | ${wl-copy} --primary
                    fi
                  done
                }

                clipboard-wl-to-x () {
                  while read; do
                    if [[ "$(${wl-paste} --no-newline | sha256sum)" != "$(${xclip} -selection clipboard -out | sha256sum)" ]]; then
                      echo "syncing clipboard wl->x"
                      ${wl-paste} --no-newline | ${xclip} -selection clipboard -in
                    fi
                  done < <(${wl-paste} --watch echo)
                }

                clipboard-x-to-wl () {
                  while ${clipnotify} -s clipboard; do
                    if [[ "$(${wl-paste} --no-newline | sha256sum)" != "$(${xclip} -selection clipboard -out | sha256sum)" ]]; then
                      echo "syncing clipboard x->wl"
                      ${xclip} -selection clipboard -out | ${wl-copy}
                    fi
                  done
                }

                clipboard-wl-to-x &
                clipboard-x-to-wl &
                primary-wl-to-x &
                primary-x-to-wl &

                ${metacity} &

                "$@"
              '';

            sodi-x-run = final.writeShellScriptBin "x-run" ''
              ${lib.getExe final.xwayland-run} -- ${lib.getExe final.sodi-x-run-env} "$@"
            '';

            xwlsat-run = final.writeShellScriptBin "xwlsat-run" ''
              n=0
              while [ -e "/tmp/.X11-unix/X$n" ]; do
                n=$((n + 1))
              done

              xwayland-satellite :$n &

              xwlsat_pid=$!

              export DISPLAY=:$n

              DISPLAY=:$n "$@"

              kill $xwlsat_pid
            '';
          })
        ];
        programs = {
          firefox = {
            #package = mkForce pkgs.firefox-wayland;
            nativeMessagingHosts.packages = with pkgs; [
              tridactyl-native
              firefoxpwa
            ];
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

        programs.nm-applet.enable = lib.mkForce false;
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
      })

      # COSMIC on niri hybrid session
      (mkIf cfg.niri.cosmicOnNiri {
        # Add the alternative startup helper and session file
        environment.systemPackages = [
          pkgs.cosmic-ext-alternative-startup
          startCosmicNiri
        ];

        # Register the wayland session
        services.displayManager.sessionPackages = [cosmicNiriSession];

        # Enable COSMIC desktop components (panels, launcher, etc.)
        services.desktopManager.cosmic.enable = true;
      })
    ];
  }

{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.profiles.desktop.niri;
  brightnessScript = pkgs.writeShellScriptBin "brightness" ''
    BUS=10
    STEP=5
    MIN=0
    MAX=100
    OSD_FILE="/tmp/brightness_osd_level"

    current=$(ddcutil --bus=$BUS getvcp 10 | grep -oP "current value\\s*=\\s*\\K[0-9]+")
    new=$current

    if [[ "$1" == "up" ]]; then
      new=$((current + STEP))
      (( new > MAX )) && new=$MAX
    elif [[ "$1" == "down" ]]; then
      new=$((current - STEP))
      (( new < MIN )) && new=$MIN
    else
      exit 1
    fi

    ddcutil --bus=$BUS setvcp 10 "$new"
    echo "$new" > "$OSD_FILE"
  '';
  colors = config.lib.stylix.colors.withHashtag;
  binds = {
    suffixes,
    prefixes,
    substitutions ? {},
  }: let
    replacer = replaceStrings (attrNames substitutions) (attrValues substitutions);
    format = prefix: suffix: let
      actual-suffix =
        if isList suffix.action
        then {
          action = head suffix.action;
          args = tail suffix.action;
        }
        else {
          inherit (suffix) action;
          args = [];
        };

      action = replacer "${prefix.action}-${actual-suffix.action}";
    in {
      name = "${prefix.key}+${suffix.key}";
      value.action.${action} = actual-suffix.args;
    };
    pairs = attrs: fn:
      concatMap (
        key:
          fn {
            inherit key;
            action = attrs.${key};
          }
      ) (attrNames attrs);
  in
    listToAttrs (pairs prefixes (prefix: pairs suffixes (suffix: [(format prefix suffix)])));
in
  with lib; {
    options.profiles.desktop.niri = {
      enable = mkEnableOption "niri profile";
      enableTablet = mkEnableOption "tablet-specific ux stuff";
    };

    config = mkIf cfg.enable {
      programs.niri.package = pkgs.niri-unstable;
      # gtk = {
      #   enable = true;
      #   iconTheme = {
      #     name = "Adwaita"; # or whatever you want
      #     package = pkgs.adwaita-icon-theme;
      #   };
      # };
      programs.niri.settings = {
        # environment."GTK_THEME" = "Adwaita:dark";
        input.keyboard.xkb.options = "compose:rwin";
        #prefer-no-csd = if cfg.enableTablet then false else true;
        prefer-no-csd = true;

        workspaces."main" = {};
        # workspaces."work" = {};
        # workspaces."gaming" = {};
        layout = {
          gaps = 12;
          struts.left = 64;
          struts.right = 64;
          struts.top =
            if cfg.enableTablet
            then -4
            else 0;
          struts.bottom =
            if cfg.enableTablet
            then 8
            else 0;
          # border = {
          #   enable = true;
          #   width = if cfg.enableTablet then 2 else 1;
          #   inactive.color = colors.base00;
          # };
          always-center-single-column = true;

          empty-workspace-above-first = true;

          preset-column-widths = [
            {proportion = 1.0 / 4.0;}
            {proportion = 1.0 / 3.0;}
            {proportion = 1.0 / 2.5;}
            {proportion = 1.0 / 2.0;}
            {proportion = 2.0 / 3.0;}
            {proportion = 3.0 / 4.0;}
            {proportion = 5.0 / 6.0;}
          ];
          preset-window-heights = [
            {proportion = 1.0 / 3.0;}
            {proportion = 0.4;}
            {proportion = 0.5;}
            {proportion = 2.0 / 3.0;}
          ];
          default-column-width = {
            proportion =
              if cfg.enableTablet
              then 2.0 / 3.0
              else 1.0 / 2.5;
          };
          # fog of war
          # focus-ring = {
          #   # enable = true;
          #   width = 10000;
          #   active.color = "#00000022";
          # };
          shadow.enable = true;

          default-column-display =
            if cfg.enableTablet
            then "tabbed"
            else "normal";

          tab-indicator = {
            position = "bottom";
            gaps-between-tabs =
              if cfg.enableTablet
              then 0
              else 10;
            width =
              if cfg.enableTablet
              then 16
              else 3;
            gap =
              if cfg.enableTablet
              then 7
              else 8;
            corner-radius =
              if cfg.enableTablet
              then 4
              else 2;
            active.color = "${colors.base0D}ff";
            inactive.color = "${colors.base03}AA";

            hide-when-single-tab = true;
            # place-within-column = true;

            # active.color = "red";
          };
        };
        input.trackball = {
          accel-profile = "adaptive";
        };
        input.touchpad = {
          tap = true;
          dwt = true;
          natural-scroll = true;
          click-method = "clickfinger";
        };
        input.tablet = {
          map-to-output = "eDP-1";
        };
        input.touch.map-to-output = "eDP-1";
        xwayland-satellite.enable = true;
        xwayland-satellite.path = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
        #hotkey-overlay.skip-at-startup = !nixosConfig.is-virtual-machine;
        #clipboard.disable-primary = true;

        screenshot-path = "~/Pictures/Screenshots/%Y-%m-%dT%H:%M:%S.png";

        switch-events = with config.lib.niri.actions; let
          sh = spawn "sh" "-c";
        in {
          tablet-mode-on.action = sh "${pkgs.glib}/bin/gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled true";
          tablet-mode-off.action = sh "${pkgs.glib}/bin/gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled false";
          lid-open.action = sh "notify-send lid-open";
          lid-close.action = sh "notify-send lid-close";
        };

        binds = with config.lib.niri.actions; let
          sh = spawn "sh" "-c";
          # screenshot-area-script = pkgs.writeShellScript "screenshot-area" ''
          #   grim -o $(niri msg --json focused-output | jq -r .name) - | swayimg --config=info.mode=off --fullscreen - &
          #   SWAYIMG=$!
          #   niri msg action do-screen-transition -d 1200
          #   sleep 1.2
          #   grim -g "$(slurp)" - | wl-copy -t image/png
          #   niri msg action do-screen-transition
          #   kill $SWAYIMG
          # '';
          # screenshot-area = spawn "${screenshot-area-script}";

          # a VM is semantically a nested session; so use the Alt key.
          # but on a physical machine, use Mod which is Super unless nested.
          Mod = "Mod";
          #   # NOTE: Are you here just to reference my niri config?
          #   # This isn't a standard option, see `./vm.mod.nix` for the definition.
          #   # If you want to just copy my binds, you likely want "Mod" instead of "${Mod}"
          #   if nixosConfig.is-virtual-machine
          #   then "Alt"
          #   else "Mod";
        in
          lib.attrsets.mergeAttrsList [
            {
              "${Mod}+T".action = spawn "wezterm";
              "${Mod}+O".action = show-hotkey-overlay;
              "${Mod}+D".action = spawn "fuzzel";
              "${Mod}+Shift+W".action = sh (
                builtins.concatStringsSep "; " [
                  "systemctl --user restart waybar.service"
                  "systemctl --user restart swaybg.service"
                ]
              );

              "${Mod}+L".action = spawn "blurred-locker";
              "${Mod}+B".action = toggle-overview;
              "${Mod}+Shift+S".action.screenshot = [];
              "Print".action.screenshot-screen = [];
              "${Mod}+Print".action.screenshot-window = [];

              "${Mod}+Menu".action = set-dynamic-cast-window;
              "${Mod}+Shift+Menu".action = set-dynamic-cast-monitor;
              "${Mod}+Delete".action = clear-dynamic-cast-target;

              "XF86AudioRaiseVolume".action = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+";
              "XF86AudioLowerVolume".action = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
              "XF86AudioMute".action = sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";

              "XF86MonBrightnessUp".action = sh "brightnessctl set 10%+";
              "XF86MonBrightnessDown".action = sh "brightnessctl set 10%-";

              "${Mod}+Q".action = close-window;

              "${Mod}+Space".action = toggle-column-tabbed-display;

              "XF86AudioNext".action = focus-column-right;
              "XF86AudioPrev".action = focus-column-left;

              "${Mod}+Tab".action = focus-window-down-or-column-right;
              "${Mod}+Shift+Tab".action = focus-window-up-or-column-left;
              "${Mod}+Z".action = focus-column-left;
              "${Mod}+X".action = focus-window-or-workspace-down;
              "${Mod}+S".action = focus-window-or-workspace-up;
              "${Mod}+C".action = focus-column-right;
              "${Mod}+Shift+Ctrl+F".action = toggle-windowed-fullscreen;
            }
            (binds {
              suffixes."Left" = "column-left";
              suffixes."Down" = "window-down";
              suffixes."Up" = "window-up";
              suffixes."Right" = "column-right";
              prefixes."${Mod}" = "focus";
              prefixes."${Mod}+Ctrl" = "move";
              prefixes."${Mod}+Shift" = "focus-monitor";
              prefixes."${Mod}+Shift+Ctrl" = "move-window-to-monitor";
              substitutions."monitor-column" = "monitor";
              substitutions."monitor-window" = "monitor";
            })
            {
              "${Mod}+V".action = switch-focus-between-floating-and-tiling;
              "${Mod}+Shift+V".action = toggle-window-floating;
            }
            (binds {
              suffixes."Home" = "first";
              suffixes."End" = "last";
              prefixes."${Mod}" = "focus-column";
              prefixes."${Mod}+Ctrl" = "move-column-to";
            })
            (binds {
              suffixes."U" = "workspace-down";
              suffixes."I" = "workspace-up";
              prefixes."${Mod}" = "focus";
              prefixes."${Mod}+Ctrl" = "move-window-to";
              prefixes."${Mod}+Shift" = "move";
            })
            (binds {
              suffixes = builtins.listToAttrs (
                map (n: {
                  name = toString n;
                  value = [
                    "workspace"
                    (n + 1)
                  ]; # workspace 1 is empty; workspace 2 is the logical first.
                }) (range 1 9)
              );
              prefixes."${Mod}" = "focus";
              prefixes."${Mod}+Ctrl" = "move-window-to";
            })
            {
              "${Mod}+Comma".action = consume-window-into-column;
              "${Mod}+Period".action = expel-window-from-column;

              "${Mod}+R".action = switch-preset-column-width;
              "${Mod}+F".action = maximize-column;
              "${Mod}+Shift+F".action = fullscreen-window;
              "${Mod}+G".action = center-column;

              "${Mod}+Minus".action = set-column-width "-10%";
              "${Mod}+Plus".action = set-column-width "+10%";
              "${Mod}+Shift+Minus".action = set-window-height "-10%";
              "${Mod}+Shift+Plus".action = set-window-height "+10%";

              "${Mod}+Shift+Escape".action = toggle-keyboard-shortcuts-inhibit;
              "${Mod}+Shift+E".action = quit;
              "${Mod}+Shift+P".action = power-off-monitors;

              "${Mod}+Shift+Ctrl+T".action = toggle-debug-tint;
            }
          ];

        animations.window-resize.custom-shader = builtins.readFile ./resize.glsl;

        outputs = {
          "eDP-1" = {
            scale = 1.0;
            backdrop-color = "#191724";
          };
          "DP-1" = {
            scale = 1.0;
            variable-refresh-rate = "on-demand";
            backdrop-color = "#191724";
          };
          "DP-4" = {
            scale = 1.0;
            variable-refresh-rate = "on-demand";
            backdrop-color = "#191724";
          };
        };
        window-rules = let
          colors = config.lib.stylix.colors.withHashtag;
        in [
          {
            draw-border-with-background = false;
            geometry-corner-radius = let
              r =
                if cfg.enableTablet
                then 14.0
                else 8.0;
            in {
              top-left = r;
              top-right = r;
              bottom-left = r;
              bottom-right = r;
            };
            clip-to-geometry = true;
          }
          {
            matches = [{is-focused = false;}];
            opacity = 0.97;
          }
          {
            # float auth stuff
            matches = [
              {app-id = "^org.kde.polkit-kde-authentication-agent";}
              {app-id = "^1Password$";}
            ];
            open-floating = true;
          }

          {
            # make it obvious which window is being recorded, and cap the size to something reasonable
            matches = [{is-window-cast-target = true;}];
            opacity = 1.0;
            focus-ring = {
              enable = true;
              width = 4;
              active.color = "#f38ba8";
              inactive.color = "#7d0d2d";
            };

            border = {
              inactive.color = "#7d0d2d";
            };

            shadow = {
              enable = true;
              spread = 10;
              softness = 7;
              offset = {
                x = 0;
                y = 0;
              };
              color = "#7d0d2d70";
            };

            tab-indicator = {
              active.color = "#f38ba8";
              inactive.color = "#7d0d2d";
            };
            max-height = 1080 + 4;
            max-width = 1920 + 4;
          }
          {
            matches = [
              {
                app-id = "^firefox$";
                title = "^Picture-in-Picture$";
              }
              {
                app-id = "^zen$";
                title = "^Picture-in-Picture$";
              }
              {
                app-id = "^zen-beta$";
                title = "^Picture-in-Picture$";
              }
              {
                app-id = "^zen-twilight$";
                title = "^Picture-in-Picture$";
              }
            ];
            opacity = 1.0;
            default-window-height = {
              proportion = 0.42;
            };
            open-floating = true;
            default-column-width = {
              proportion =
                if cfg.enableTablet
                then 0.8
                else 0.4;
            };
            default-floating-position = {
              relative-to = "top-left";
              x = 0;
              y = 0;
            };
          }
          {
            # the terminal is already transparent from stylix
            matches = [
              {app-id = "^kitty$";}
              {app-id = "^alacritty$";}
              {app-id = "^ghostty$";}
              {app-id = "^wezterm$";}
            ];
            opacity = 1.0;
            default-window-height = {
              proportion = 0.4;
            };
          }
          {
            matches = [{app-id = "^niri$";}];
            opacity = 1.0;
          }
          {
            matches = [
              {
                app-id = "^firefox$";
                title = "Private Browsing";
              }
            ];
            border.active.color = colors.base0E;
          }
          {
            matches = [
              {
                app-id = "^signal$";
              }
              {
                app-id = "^BeeperTexts$";
              }
            ];
            block-out-from = "screencast";
          }
        ];

        gestures.dnd-edge-view-scroll = {
          trigger-width = 64;
          delay-ms = 250;
          max-speed = 12000;
        };

        gestures.dnd-edge-workspace-switch = {
          trigger-height = 100;
          delay-ms = 100;
          max-speed = 3000;
        };

        layer-rules = [
          {
            matches = [{namespace = "waybar";}];

            opacity = 0.8;
          }
          # {
          #   matches = [ { namespace = "quickshell"; } ];

          #   opacity = 0.9;
          # }
          # {
          #   matches = [{namespace = "wallpaper$";}];
          #   place-within-backdrop = true;
          # }
        ];
      };
      home.packages = with pkgs; [
        # useful for testing webcams, etc
        cheese
        brightnessScript
        brightnessctl
      ];

      programs.zen-browser = {
        enable = true;
        policies = {
          DisableAppUpdate = true;
          DisableTelemetry = true;
          # find more options here: https://mozilla.github.io/policy-templates/
        };
        nativeMessagingHosts = [
          pkgs.tridactyl-native
          pkgs.firefoxpwa
        ];
      };
      programs.fuzzel = {
        enable = true;
        settings = {
          main = {
            terminal = "wezterm";
            font = lib.mkForce (
              if cfg.enableTablet
              then "IBM Plex Sans:12"
              else "IBM Plex Sans:10"
            );
          };
        };
      };
      stylix.targets.zen-browser.enable = false;
      services.swaync = {
        enable = true;
      };
      services.cliphist = {
        enable = true;
        allowImages = true;
      };
      systemd.user.services."swaybg" = {
        Unit = {
          Description = "wallpapers! brought to you by stylix! :3";
          PartOf = ["graphical-session.target"];
          After = ["graphical-session.target"];
        };
        Install.WantedBy = ["graphical-session.target"];
        Service = {
          ExecStart = "${lib.getExe pkgs.swaybg} -m fill -i ${config.stylix.image}";
          Restart = "on-failure";
        };
      };

      #### gnome-keyring ########################################################
      services.gnome-keyring = {
        enable = true;
        components = [
          "pkcs11"
          "secrets"
          "ssh"
        ];
      };

      #### autostart services ####################################################
      services.gammastep = {
        enable = true;
        latitude = 43.0;
        longitude = -79.0;
        provider = "manual";
        tray = true;
      };
    };
  }

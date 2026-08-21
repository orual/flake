{
  config,
  lib,
  ...
}: let
  cfg = config.profiles.noctalia;
in {
  options.profiles.noctalia = with lib; {
    enable = mkEnableOption "noctalia profile";
  };

  config = lib.mkIf cfg.enable {
    programs.noctalia = {
      enable = true;
      systemd.enable = false;
      settings = {
        shell = {
          corner_radius_scale = 0.2;
          time_format = "{:%H:%M}";
          date_format = "%a %Y-%m-%d";
          avatar_path = "/home/orual/flake/modules/home/profiles/Vin_Pride_pfp.png";
          show_location = true;
        };
        wallpaper = {
          enabled = true;
          transition_on_startup = true;
        };
        theme = {
          mode = "dark";
          source = "custom";
          custom_palette = "rose-pine-moon";
        };
        location = {
          auto_locate = true;
        };
        bar.main = {
          position = "top";
          start = ["launcher" "cpu" "ram" "temperature" "media"];
          center = ["clock" "workspaces" "active_window"];
          end = ["tray" "notifications" "battery" "volume" "brightness" "control-center"];
        };
        widget = {
          clock = {
            format = "%a %Y-%m-%d %H:%M";
            vertical_format = "%H\n%M - %b %d";
          };
          workspaces = {
            hide_when_empty = false;
          };
        };
      };
      customPalettes = {
        rose-pine-moon = {
          dark = {
            mPrimary = "#ea9a97";
            mOnPrimary = "#232136";
            mSecondary = "#9ccfd8";
            mOnSecondary = "#232136";
            mTertiary = "#3e8fb0";
            mOnTertiary = "#e0def4";
            mError = "#eb6f92";
            mOnError = "#232136";
            mSurface = "#232136";
            mOnSurface = "#e0def4";
            mSurfaceVariant = "#393552";
            mOnSurfaceVariant = "#908caa";
            mOutline = "#44415a";
            mShadow = "#232136";
            mHover = "#56526e";
            mOnHover = "#e0def4";
            terminal = {
              background = "#232136";
              foreground = "#e0def4";
              cursor = "#e0def4";
              cursorText = "#232136";
              selectionBg = "#393552";
              selectionFg = "#e0def4";
              normal = {
                black = "#232136";
                red = "#eb6f92";
                green = "#9ccfd8";
                yellow = "#f6c177";
                blue = "#3e8fb0";
                magenta = "#c4a7e7";
                cyan = "#9ccfd8";
                white = "#e0def4";
              };
              bright = {
                black = "#6e6a86";
                red = "#eb6f92";
                green = "#9ccfd8";
                yellow = "#f6c177";
                blue = "#3e8fb0";
                magenta = "#c4a7e7";
                cyan = "#9ccfd8";
                white = "#e0def4";
              };
            };
          };
        };
      };
    };
  };
}

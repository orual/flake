{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.profiles.noctalia;
in {
  options.profiles.noctalia = with lib; {
    enable = mkEnableOption "noctalia profile";
  };

  config = lib.mkIf cfg.enable {
    programs.noctalia-shell.systemd.enable = true;
    # configure options
    programs.noctalia-shell = {
      enable = true;
      settings = {
        bar = {
          density = "default";
          position = "top";
          # floating = true;
          # showCapsule = true;
          # useSeparateOpacity = true;
          # capsuleOpacity = lib.mkForce 1;
          # backgroundOpacity = lib.mkForce 0.01;
          widgets = {
            left = [
              {
                id = "Launcher";
              }
              {
                id = "SystemMonitor";
              }
              {
                id = "MediaMini";
                useFixedWidth = false;
                maxWidth = 400;
              }
            ];
            center = [
              {
                formatHorizontal = "ddd yyyy-MM-dd HH:mm";
                formatVertical = "HH mm - MMM dd";
                id = "Clock";
                useMonospacedFont = true;
                usePrimaryColor = true;
              }
              {
                hideUnoccupied = false;
                id = "Workspace";
              }
              {
                id = "ActiveWindow";
                useFixedWidth = false;
                maxWidth = 400;
              }
            ];
            right = [
              {
                id = "Tray";
              }
              {
                id = "NotificationHistory";
              }
              {
                alwaysShowPercentage = false;
                id = "Battery";
                warningThreshold = 30;
              }
              {
                id = "Volume";
              }
              {
                id = "Brightness";
              }
              {
                id = "ControlCenter";
                useDistroLogo = true;
              }
            ];
          };
        };
        colorSchemes.predefinedScheme = "Rose Pine Moon";
        general = {
          avatarImage = "/home/orual/flake/modules/home/profiles/Vin_Pride_pfp.png";
          radiusRatio = 0.2;
        };
        location = {
          monthBeforeDay = true;
          name = "Toronto, Canada";
        };
        wallpaper = {
          enabled = true;
          overviewEnabled = true;
        };
        colors = {
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
        };
      };
    };
  };
}

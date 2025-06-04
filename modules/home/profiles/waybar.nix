{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.profiles.waybar;
  icons = rec {
    calendar = "󰃭 ";
    clock = " ";
    battery.charging = "󱐋";
    battery.horizontal = [" " " " " " " " " "];
    battery.vertical = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
    battery.levels = battery.vertical;
    network.disconnected = "󰤮 ";
    network.ethernet = "󰈀 ";
    network.strength = ["󰤟 " "󰤢 " "󰤥 " "󰤨 "];
    bluetooth.on = "󰂯";
    bluetooth.off = "󰂲";
    bluetooth.battery = "󰥉";
    volume.source = "󱄠";
    volume.muted = "󰝟";
    volume.levels = ["󰕿" "󰖀" "󰕾"];
    idle.on = "󰈈 ";
    idle.off = "󰈉 ";
    vpn = "󰌆 ";

    notification.red_badge = "<span foreground='red'><sup></sup></span>";
    notification.bell = "󰂚";
    notification.bell-badge = "󱅫";
    notification.bell-outline = "󰂜";
    notification.bell-outline-badge = "󰅸";
  };
in {
  options.profiles.waybar = with lib; {
    enable = mkEnableOption "waybar profile";
  };

  config = lib.mkIf cfg.enable {
    programs.waybar = {
      enable = true;
      systemd.enable = true;
    };
    programs.waybar.settings.mainBar = {
      layer = "top";
      #position = "bottom";
      modules-left = ["wireplumber" "wireplumber#source" "idle_inhibitor"];
      modules-center = ["niri/workspaces" "niri/window" "clock#date" "clock"];
      modules-right = ["tray" "network" "bluetooth" "bluetooth#battery" "custom/swaync"];

      battery = {
        interval = 5;
        format = "{icon}  {capacity}%";
        format-charging = "{icon}  {capacity}% ${icons.battery.charging}";
        format-icons = icons.battery.levels;
        states.warning = 30;
        states.critical = 15;
      };

      clock = {
        interval = 1;
        format = "${icons.clock} {:%H:%M:%S}";
      };

      "clock#date" = {
        format = "${icons.calendar} {:%Y-%m-%d}";
      };
      "clock#week" = {
        format = "${icons.calendar} {:%W}";
      };

      network = {
        tooltip-format = "{ifname}";
        format-disconnected = icons.network.disconnected;
        format-ethernet = icons.network.ethernet;
        format-wifi = "{icon} {essid}";
        format-icons = icons.network.strength;
      };

      bluetooth = {
        format = "{icon}";
        format-disabled = "";
        format-icons = {
          inherit (icons.bluetooth) on off;
          connected = icons.bluetooth.on;
        };
        format-connected = "{icon} {device_alias}";
      };
      "bluetooth#battery" = {
        format = "";
        format-connected-battery = "${icons.bluetooth.battery} {device_battery_percentage}%";
      };

      tray = {
        show-passive-items = true;
        spacing = "40";
      };

      wireplumber = {
        format = "{icon} {volume}%";
        format-muted = "${icons.volume.muted} {volume}%";
        format-icons = icons.volume.levels;
        reverse-scrolling = 1;
        tooltip = false;
      };

      "wireplumber#source" = {
        format = "${icons.volume.source} {node_name}";
        tooltip = false;
        on-click = "${pkgs.helvum}";
      };

      # "group/volume" = {
      #   orientation = "horizontal";
      #   modules = [
      #     "wireplumber"
      #     "wireplumber#source"
      #   ];
      #   drawer = {
      #     transition-left-to-right = true;
      #   };
      # };

      idle_inhibitor = {
        format = "{icon}";
        format-icons = {
          activated = icons.idle.on;
          deactivated = icons.idle.off;
        };
      };

      "niri/workspaces" = {
      };

      "niri/window" = {
      };

      "custom/swaync" = {
        tooltip = false;
        format = "{icon}";
        format-icons = {
          notification = "<span foreground='red'><sup></sup></span>";
          none = icons.notification.bell-outline;
          none-cc-open = icons.notification.bell;
          dnd-notification = "<span foreground='red'><sup></sup></span>";
          dnd-none = "";
          inhibited-notification = "<span foreground='red'><sup></sup></span>";
          inhibited-none = "";
          dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
          dnd-inhibited-none = "";
        };
        return-type = "json";
        exec-if = "which swaync-client";
        exec = "swaync-client -swb";
        # exec = ''swaync-client -swb | jq -c 'if .class | .[]? // . | contains("cc-open") then .alt += "-cc-open" else . end' '';
        on-click = "swaync-client -t -sw";
        on-click-right = "swaync-client -d -sw";
        escape = true;
      };
    };
    stylix.targets.waybar.enable = false;
    programs.waybar.style = let
      colors = config.lib.stylix.colors;
      modules = s: "${s ".modules-left"}, ${s ".modules-center"}, ${s ".modules-right"}";
      module = s: modules (m: "${m} > ${s} > *");
    in ''
      * {
          border: none;
          font-family: ${config.stylix.fonts.sansSerif.name};
          font-size: 16px;
          color: #${colors.base06};
      }

      window#waybar {
          background: transparent;
          font-size: 2em;
      }

      ${modules lib.id} {
          background: transparent;
          margin: 3px 7px;
      }

      ${module "*"} {
        margin: 3px 1px;
        padding: 5px 7px;
        background: #${colors.base00};
      }
      ${module ":first-child"} {
          padding-left: 10px;
          border-top-left-radius: 10px;
          border-bottom-left-radius: 10px;
      }

      ${module ":last-child"} {
          padding-right: 10px;
          border-top-right-radius: 10px;
          border-bottom-right-radius: 10px;
      }

      ${module ":not(:first-child)"} {
          border-top-left-radius: 3px;
          border-bottom-left-radius: 3px;
      }

      ${module ":not(last-child)"} {
          border-top-right-radius: 3px;
          border-bottom-right-radius: 3px;
      }

      #workspaces button.focused {
        background: #${colors.base07}

      }
      #window {
        padding-left: 15px;
        padding-right: 15px;
      }

      #wireplumber:not(.source).muted {
          color: #${colors.yellow};
      }

      #idle_inhibitor.activated {
        color: #${colors.yellow};
      }

      #battery.charging {
          color: #${colors.green};
      }

      #battery.warning:not(.charging) {
          color: #${colors.yellow};
      }

      #battery.critical:not(.charging) {
          animation: critical-blink steps(8) 1s infinite alternate;
      }

      @keyframes critical-blink {
          to {
              color: #${colors.red};
          }
      }
    '';
  };
}

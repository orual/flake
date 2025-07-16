{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.profiles.ags;
  icons = rec {
    calendar = "󰃭 ";
    clock = " ";
    battery.charging = "󱐋";
    battery.horizontal = [
      " "
      " "
      " "
      " "
      " "
    ];
    battery.vertical = [
      "󰁺"
      "󰁻"
      "󰁼"
      "󰁽"
      "󰁾"
      "󰁿"
      "󰂀"
      "󰂁"
      "󰂂"
      "󰁹"
    ];
    battery.levels = battery.vertical;
    network.disconnected = "󰤮 ";
    network.ethernet = " 󰈀 ";
    network.strength = [
      " 󰤟 "
      " 󰤢 "
      " 󰤥 "
      " 󰤨 "
    ];
    bluetooth.on = "󰂯";
    bluetooth.off = "󰂲";
    bluetooth.battery = "󰥉";
    volume.source = "󱄠 ";
    volume.muted = "󰝟";
    volume.levels = [
      "󰕿"
      "󰖀"
      "󰕾"
    ];
    idle.on = " 󰈈 ";
    idle.off = " 󰈉 ";
    vpn = "󰌆 ";
    spotify = "󰓇 ";
    youtube = " ";
    play = "󰐊 ";
    pause = "󰏤 ";
    play-pause = "󰐎 ";

    notification.red_badge = "<span foreground='red'><sup></sup></span>";
    notification.bell = "󰂚";
    notification.bell-badge = "󱅫";
    notification.bell-outline = "󰂜";
    notification.bell-outline-badge = "󰅸";
  };
in
{
  options.profiles.ags = with lib; {
    enable = mkEnableOption "astal shell profile";
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.astal-shell = {
      Unit = {
        Description = "Astal Shell";
        After = [ "graphical-session.target" ];
        Wants = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.astal-shell}/bin/astal-shell";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
    home.packages = with pkgs; [
      astal-shell
    ];
    # programs.ags = {
    #   enable = true;
    #   configDir = null;
    #   extraPackages = [ pkgs.astal-shell ];
    # };
  };
}

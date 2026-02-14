# NixOS module for Framework AMD laptops
#
# See also the `nixos-hardware` modules for Framework:
# https://github.com/NixOS/nixos-hardware/blob/33a97b5814d36ddd65ad678ad07ce43b1a67f159/framework/README.md

{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.hardware.framework-twelve;
in
with lib;
{

  options.hardware.framework-twelve = {
    enable = mkEnableOption "Framework twelve profile";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      fw-ectool
    ];

    ### enable services ###
    services = {
      # use `fwupdmgr` for updating Framework firmware
      fwupd.enable = mkDefault true;

      power-profiles-daemon.enable = mkDefault true;
    };

    # enable the TPM profile
    hardware.tpm.enable = mkDefault true;

    ### misc hardware support tweaks ###

    boot.kernelParams = [

    ];

    # necessary to enable 802.11ax for the MEDIATEK WiFi chipset, as per:
    # https://community.frame.work/t/framework-nixos-linux-users-self-help/31426/77
    hardware.wirelessRegulatoryDatabase = true;
    # NOTE: you probably want to change this if you're in an 802.11
    # regulatory domain other than the US?
    boot.extraModprobeConfig = ''

    '';
  };

}

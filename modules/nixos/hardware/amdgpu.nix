# Configuration to enable TPM on machines that have one.
{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.hardware.amdgpu;
in
  with lib; {
    options.hardware.amdgpu = {enable = mkEnableOption "AMDGPU profile";};

    config = mkIf cfg.enable {
      boot.initrd.kernelModules = ["amdgpu"];
      hardware.graphics.extraPackages = [pkgs.mesa.drivers];

      hardware.graphics.enable = true;
      hardware.graphics.enable32Bit = true;
      hardware.amdgpu.overdrive.enable = true;

      #hardware.amdgpu.opencl.enable = true;
      programs.tuxclocker = {
        enable = true;
      };
    };
  }

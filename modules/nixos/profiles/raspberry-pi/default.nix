{ config, pkgs, lib, ... }:
let
  cfg = config.profiles.raspberry-pi;
  mkUdevRules = ({ name, text }:
    pkgs.writeTextFile {
      inherit name text;
      destination = "/etc/udev/rules.d/75-${name}.rules";
    });
in
with lib;
{
  imports = [
    ./pi3.nix
    ./pi4.nix
    ./pi5.nix
  ];

  options.profiles.raspberry-pi = {
    i2c.enable = mkEnableOption "Raspberry Pi I2C devices";
    spi.enable = mkEnableOption "Raspberry Pi SPI devices";
    gpio.enable = mkEnableOption "Raspberry Pi GPIO utilities";
    poe-hat.enable = mkEnableOption "Raspberry Pi PoE HAT";
  };

  config = mkIf (cfg.pi3.enable || cfg.pi4.enable || cfg.pi5.enable) (mkMerge [
    {
      security.sudo-rs.enable = mkForce false;
      security.sudo.enable = true;

      boot = {
        initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
        loader = {
          grub.enable = false;
          generic-extlinux-compatible.enable = true;
        };
        tmp.cleanOnBoot = true;
      };

      # don't install documentation, in order to save space on the SD card
      documentation.nixos.enable = false;
      # enable automatic nix gc
      nix.gc = {
        automatic = true;
        options = "--delete-older-than 30d";
      };

      environment.systemPackages = with pkgs; [ libraspberrypi ];

      hardware.deviceTree.overlays = [
        # enable I2C-1 on the Raspberry Pi 3
        #
        # TODO(orual): `hardware.raspberry-pi."4".i2c1.enable` in
        # `nixos-hardware` will add an *almost identical* devicetree overlay,
        # except it has `compatible = "brcm,bcm2711"` in it, making it only work
        # on the Pi 4, and not the Pi 3. see:
        # https://github.com/NixOS/nixos-hardware/blob/7b49d3967613d9aacac5b340ef158d493906ba79/raspberry-pi/4/i2c.nix
        #
        # it would be nice to upstream this change to nixos-hardware eventually
        # to add i2c support for the Pi 3.
        (mkIf cfg.i2c.enable {
          name = "i2c1-okay-overlay";
          dtsFile = ./dts/i2c1.dts;
        })
        (mkIf cfg.spi.enable {
          name = "spi";
          dtsFile = ./dts/spi.dts;
        })
        # (mkIf cfg.spi.enable
        #   { name = "spi0-0cs.dtbo"; dtboFile = "${pkgs.device-tree_rpi.overlays}/spi0-0cs.dtbo"; })

        (mkIf cfg.poe-hat.enable {
          name = "poe-hat";
          # TODO(orual): make pi3-specific?
          dtsFile = ./dts/poe-hat-pi3.dts;
        })
      ];

    }
    (mkIf cfg.i2c.enable {
      hardware.i2c.enable = true;
      # also, it's nice to have the i2c-tools package installed for debugging...
      environment.systemPackages = with pkgs; [ i2c-tools ];
    })
    (mkIf cfg.spi.enable {
      users.groups.spi = { };
      users.users.orual.extraGroups = [ "spi" ];

      services.udev.packages = [
        (mkUdevRules
          {
            name = "spi";
            text = ''
              SUBSYSTEM=="spidev", KERNEL=="spidev0.0", GROUP="spi", MODE="0660"
            '';
          })
      ];
    })
    (mkIf cfg.gpio.enable {
      users.groups.gpio = { };
      users.users.orual.extraGroups = [ "gpio" ];

      environment.systemPackages = with pkgs; [ wiringpi gpio-utils ];

      services.udev.packages = [
        (mkUdevRules
          {
            name = "gpio";
            text = ''
              KERNEL=="gpiochip0*", GROUP="gpio", MODE="0660"
              SUBSYSTEM=="gpiomem", GROUP="gpio", MODE="0660"
            '';
          })
      ];
    })
  ]);
}

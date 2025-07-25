{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  networking.hostName = "sylpherena"; # Define your hostname.

  profiles = {
    docs.enable = true;
    laptop.enable = true;
    desktop = {
      enable = true;
      gnome3.enable = true;
      niri.enable = true;
    };
    observability.enable = true;
    arm-cross-dev.enable = true;
    nix-ld.enable = true;
    games.enable = true;
  };

  hardware = {
    probes = {
      cmsis-dap.enable = true;
      espressif.enable = true;
      st-link.enable = true;
      cynthion.enable = true;
      glasgow.enable = true;
    };
    tpm.enable = true;
    framework-twelve.enable = true;
  };

  #### System configuration ####

  # Bootloader.
  boot = {
    loader.efi.canTouchEfiVariables = true;

    # use the latest stable Linux kernel
    kernelPackages = pkgs.linuxPackages_latest;

    # initrd.luks.devices."luks-c8e922ff-11e1-473c-a52e-c2b86a042e44".device =
    #   "/dev/disk/by-uuid/c8e922ff-11e1-473c-a52e-c2b86a042e44";

    ### secureboot using Lanzaboote ###
    # TODO: move this to a module?
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      # don't keep more than 16 old configurations, to keep the /boot partition
      # from filling up.
      configurationLimit = 16;
    };

    # Lanzaboote currently replaces the systemd-boot module.
    # This setting is usually set to true in configuration.nix
    # generated at installation time. So we force it to false
    # for now.
    loader.systemd-boot.enable = mkForce false;
    #loader.systemd-boot.enable = true;
  };
  fileSystems = {
    "/".options = [ "compress=zstd" ];
    "/home".options = [ "compress=zstd" ];
    "/nix".options = [
      "compress=zstd"
      "noatime"
    ];
    #"/swap".options = [ "noatime" ];
  };
  #swapDevices = [{
  #  device = "/swap/swapfile";
  #  size = 72*1024; # Creates an 8GB swap file
  #}];

  environment.systemPackages = with pkgs; [
    # For debugging and troubleshooting Secure Boot.
    sbctl
  ];

  programs = {
    # Used specifically for its (quite magical) "copy as html" function.
    gnome-terminal.enable = true;

    #xfel.enable = true;
  };

  services = {
    desktopManager.cosmic.enable = true;
    btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/" ];
    };

    pcscd.enable = true;
    udev.packages = [ pkgs.yubikey-personalization ];
  };

  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };
  security.pam.yubico = {
    enable = true;
    debug = false;
    mode = "challenge-response";
    id = [ "26917133" ];
  };

  # disable the Gnome keyring, since we are using 1password to manage secrets
  # instead.
  # services.gnome.gnome-keyring.enable = mkForce false;
  # security.pam.services.login.enableGnomeKeyring = mkForce false;

  # NO!! i DON'T WANT wpa_supplicant! stop making it be there!
  networking.wireless.enable = mkForce false;

  users.motd = ''
    ┌┬────────────────┐
    ││ ORUAL NETWORKS │
    └┴────────────────┘
    ${config.networking.hostName}: mobile workstation
  '';

  # As of firmware v03.03, a bug in the EC causes the system to wake if AC is
  # connected despite the lid being closed. The following works around this,
  # with the trade-off that keyboard presses also no longer wake the system.
  # see https://github.com/NixOS/nixos-hardware/tree/7763c6fd1f299cb9361ff2abf755ed9619ef01d6/framework/13-inch/7040-amd#suspendwake-workaround
  # hardware.framework.amd-7040.preventWakeOnAC = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}

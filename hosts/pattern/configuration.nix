{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [./hardware-configuration.nix ./filesystems.nix];

  system.stateVersion = "24.11";

  profiles = let
    rootDomain = "nonbinary.computer";
  in {
    docs.enable = true;
    games.enable = true;
    desktop = {
      #gnome3.enable = true;
      niri.enable = true;
    };
    #observability.enable = false;
    observability = {
      enable = true;
      observer = {
        enable = true;
        enableUnifi = true;
        victoriametrics.enable = false;
        inherit rootDomain;
      };
      snmp.enable = true;
    };
    ### Turn this back on when I get the DNS stuff set up right
    nginx = {
      enable = true;
      domain = rootDomain;
      acmeSubdomain = "home";
    };
    # enable the correct perf tools for this kernel version
    perftools.enable = true;
    zfs.enable = true;

    arm-cross-dev.enable = true;
    nix-ld.enable = true;
  };

  hardware = {
    amdgpu.enable = true;
    graphics.extraPackages = [pkgs.mesa];
    probes = {
      cmsis-dap.enable = true;
      espressif.enable = true;
      st-link.enable = true;
      cynthion.enable = true;
      glasgow.enable = true;
    };
  };

  #### Boot configuration ####
  boot = {
    loader = {
      # Use the systemd-boot EFI boot loader.
      systemd-boot = {
        enable = true;
        # don't keep more than 32 old configurations, to keep the /boot
        # partition from filling up.
        configurationLimit = 32;
      };
      efi.canTouchEfiVariables = true;
    };
    # Fixes some issues with the Focusrite Scarlett 8i6
    extraModprobeConfig = ''
      options snd_usb_audio vid=0x1235 pid=0x8212 device_setup=1
    '';
    # Use this to track the latest Linux kernel that has ZFS support.
    # This is generally not as necessary while using `zfsUnstable = true`.
    # kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

    # The Zen kernel is tuned for better performance on desktop/workstation
    # machines, rather than power efficiency on laptops/small devices. Use that!
    # kernelPackages = pkgs.linuxPackages_zen;

    ### configuration for unlocking the encrypted ZFS root dataset over SSH ###
    # based on
    # https://gitlab.com/usmcamp0811/dotfiles/-/blob/nixos/modules/nixos/system/zfs/default.nix
    #
    # TO REMOTELY UNLOCK ZPOOL:
    #
    # ssh root@10.1.2.58 -p 22
    # zfs load-key -a
    # <enter password>
    #
    # kernel modules for network adapters
    kernelModules = ["e1000e" "alx" "r8169" "igb" "cdc_ether" "r8152"];
    # TODO(orual): this could be a static IP so that we don't depend on DHCP
    # working to boot...
    kernelParams = [
      "ip=dhcp"
      "reboot=acpi"
      "amd_pstate=guided"
      #"amdgpu.dcdebugmask=0x12"
    ];

    # additional kernel modules
    initrd.availableKernelModules = [
      "usb_storage"
      "sd_mod"
      # enable initrd kernel modules for network adapters.
      #
      # these can be found using `sudo lspci -v -nn -d '::0200'` to find Ethernet
      # controllers and `sudo lspci -v -nn -d '::0280'` to find wireless
      # controllers, and then looking for the "Kernel driver in use" line.
      "r8169" # Realtek 2.5G Ethernet
      "rtw89_8852be" # Realtek Wifi
      # other network adapters. these aren't currently present on my system, but
      # let's enable them anyway in case it grows additional hardware
      # later.abort
      "thunderbolt"
      "usbnet"
      "r8152"
      "igc"
      "cdc_ether"
    ];
    initrd.kernelModules = ["amdgpu"];
    initrd.network = {
      enable = true;
      ssh = {
        enable = true;
        port = 22;
        authorizedKeys = config.users.users.orual.openssh.authorizedKeys.keys;
        # WARNING: these must actually exist :)
        hostKeys = [
          "/etc/ssh/ssh_host_rsa_key"
          "/etc/ssh/ssh_host_ed25519_key"
        ];
      };
    };
  };
  virtualisation.vmware.host = {
    enable = true;
  };

  #### System configuration ####
  networking = {
    # machine's hostname
    hostName = "pattern";
    # this has to be a unique 32-bit number. ZFS requires us to define this.
    hostId = "FADEFACE";

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    useDHCP = false;
    interfaces = let
      wakeOnLan = {
        enable = true;
        policy = ["unicast" "magic"];
      };
      # disable dhcpd and use networkmanager instead.
      useDHCP = true;
    in {
      eno1 = {inherit wakeOnLan useDHCP;};
      wlp12s0 = {inherit useDHCP;};
    };
  };

  # This is a deskop machine. Use the high-performance frequency profile rather
  # than the low-power one.
  powerManagement.cpuFreqGovernor = "performance";

  # high-DPI console font
  #console.font = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";

  # i have 24 cores
  nix.settings.max-jobs = 24;

  #### Programs ####
  programs = {
    # Used specifically for its (quite magical) "copy as html" function.
    gnome-terminal.enable = true;
    openrgb.enable = true;

    #xfel.enable = true;
  };

  #### Services ####
  services = {
    ollama = {
      enable = true;
      acceleration = "rocm";
      rocmOverrideGfx = "10.3.6";
    };
    displayManager.gdm.autoSuspend = false;
    openrgb.enable = true;
    # FOR CVE REASONS
    printing.enable = lib.mkForce false;

    # Fix immediate wakeups from suspend
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="pci", DRIVER=="pcieport", ATTR{power/wakeup}="disabled"
      ACTION=="remove",\
        ENV{ID_BUS}=="usb",\
        ENV{ID_MODEL_ID}=="0407",\
        ENV{ID_VENDOR_ID}=="1050",\
        ENV{ID_VENDOR}=="Yubico",\
        RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
    '';
    pcscd.enable = true;
    udev.packages = [pkgs.yubikey-personalization];
  };

  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };
  security.pam.yubico = {
    enable = true;
    debug = true;
    mode = "challenge-response";
    id = ["26917133"];
  };

  # services.tailscale =
  #   let
  #     labMgmtNet = "10.0.50.0/24";
  #     labServerNet = "10.0.60.0/24";
  #   in
  #   {
  #     useRoutingFeatures = "server";
  #     extraUpFlags = [
  #       "--advertise-routes=${labMgmtNet},${labServerNet}"
  #     ];
  #   };

  # disable the Gnome keyring, since we are using 1password to manage secrets
  # instead.
  # services.gnome.gnome-keyring.enable = lib.mkForce false;
  # security.pam.services.login.enableGnomeKeyring = lib.mkForce false;

  users.motd = ''
    ┌┬────────────────┐
    ││ ORUAL NETWORKS │
    └┴────────────────┘
    ${config.networking.hostName}: workstation
  '';
}

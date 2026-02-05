# Hardware configuration for Proxmox VM
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  cfg = config.profiles.k3s-node;
in {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # Proxmox image configuration via image.modules (new style)
  image.modules.proxmox = {
    proxmox = {
      qemuConf =
        {
          cores = cfg.vm.cores;
          memory = cfg.vm.memory;
          bios = cfg.vm.proxmox.bios;
          net0 = cfg.vm.proxmox.net0;
          agent = cfg.vm.proxmox.agent;
          scsihw = cfg.vm.proxmox.scsihw;
          additionalSpace = cfg.vm.proxmox.additionalSpace;
          bootSize = cfg.vm.proxmox.bootSize;
          virtio0 = "${cfg.vm.proxmox.diskStorage}:vm-9999-disk-0";
        }
        // lib.optionalAttrs (cfg.vm.proxmox.partitionTableType != null) {
          partitionTableType = cfg.vm.proxmox.partitionTableType;
        };
      cloudInit = {
        enable = true;
        defaultStorage = cfg.vm.proxmox.cloudInitStorage;
      };
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  # Boot configuration for UEFI VM
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
    growPartition = true;

    initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "virtio_pci"
      "virtio_scsi"
      "sd_mod"
      "sr_mod"
    ];

    kernelModules = ["kvm-amd" "kvm-intel"];

    initrd.kernelModules = [
      "virtio_balloon"
      "virtio_console"
      "virtio_rng"
      "virtio_gpu"
    ];
  };

  # No swap for k3s nodes (kubernetes prefers no swap)
  swapDevices = [];

  # Use DHCP for networking (cloud-init will configure)
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}

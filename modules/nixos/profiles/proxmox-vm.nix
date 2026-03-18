# Proxmox VM image generation profile
#
# Extracted from k3s-node.nix so that any host can generate Proxmox VM images
# without requiring k3s.
{
  config,
  lib,
  modulesPath,
  ...
}:
with lib; let
  cfg = config.profiles.proxmox-vm;
in {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  options.profiles.proxmox-vm = {
    enable = mkEnableOption "Proxmox VM image generation";

    cores = mkOption {
      type = types.int;
      default = 2;
      description = "Number of CPU cores";
    };

    memory = mkOption {
      type = types.int;
      default = 2048;
      description = "Memory in MB";
    };

    diskSize = mkOption {
      type = types.str;
      default = "20G";
      description = "Root disk size";
    };

    proxmox = {
      bios = mkOption {
        type = types.enum ["seabios" "ovmf"];
        default = "ovmf";
        description = "BIOS type (seabios or ovmf/UEFI)";
      };

      partitionTableType = mkOption {
        type = types.nullOr (types.enum ["efi" "hybrid" "legacy" "legacy+gpt"]);
        default = null;
        description = "Partition table type (defaults based on bios selection)";
      };

      net0 = mkOption {
        type = types.str;
        default = "virtio=00:00:00:00:00:00,bridge=vmbr0,firewall=1";
        description = "Network interface configuration";
      };

      agent = mkOption {
        type = types.bool;
        default = true;
        description = "Enable QEMU guest agent";
      };

      scsihw = mkOption {
        type = types.str;
        default = "virtio-scsi-single";
        description = "SCSI controller type";
      };

      additionalSpace = mkOption {
        type = types.str;
        default = "10G";
        description = "Additional disk space beyond base image size";
      };

      bootSize = mkOption {
        type = types.str;
        default = "256M";
        description = "Boot partition size";
      };

      cloudInitStorage = mkOption {
        type = types.str;
        default = "local-zfs";
        description = "Storage backend for cloud-init drive";
      };

      diskStorage = mkOption {
        type = types.str;
        default = "local-zfs";
        description = "Storage name for the VM disk in virtio0";
      };
    };
  };

  config = mkIf cfg.enable {
    # Proxmox image configuration
    image.modules.proxmox = {
      proxmox = {
        qemuConf =
          {
            cores = cfg.cores;
            memory = cfg.memory;
            bios = cfg.proxmox.bios;
            net0 = cfg.proxmox.net0;
            agent = cfg.proxmox.agent;
            scsihw = cfg.proxmox.scsihw;
            additionalSpace = cfg.proxmox.additionalSpace;
            bootSize = cfg.proxmox.bootSize;
            virtio0 = "${cfg.proxmox.diskStorage}:vm-9999-disk-0";
          }
          // optionalAttrs (cfg.proxmox.partitionTableType != null) {
            partitionTableType = cfg.proxmox.partitionTableType;
          };
        cloudInit = {
          enable = true;
          defaultStorage = cfg.proxmox.cloudInitStorage;
        };
      };
    };

    # Filesystems
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      autoResize = true;
      fsType = "ext4";
    };
    fileSystems."/boot" = {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
    };

    # Boot configuration
    boot = {
      loader = {
        systemd-boot = {
          enable = true;
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

    swapDevices = [];
    networking.useDHCP = mkDefault true;
    nixpkgs.hostPlatform = mkDefault "x86_64-linux";

    # QEMU guest agent
    services.qemuGuest.enable = mkDefault true;

    # Server defaults (no sleep/suspend)
    profiles.server.enable = true;
  };
}

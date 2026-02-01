# Hardware configuration for Proxmox VM
{ config, lib, pkgs, modulesPath, ... }:

let
  cfg = config.profiles.k3s-node;
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/virtualisation/proxmox-image.nix")
  ];

  # Proxmox image configuration (uses options from k3s-node profile)
  proxmox = {
    qemuConf = {
      cores = cfg.vm.cores;
      memory = cfg.vm.memory;
      bios = cfg.vm.proxmox.bios;
      net0 = cfg.vm.proxmox.net0;
      agent = cfg.vm.proxmox.agent;
      scsihw = cfg.vm.proxmox.scsihw;
      additionalSpace = cfg.vm.proxmox.additionalSpace;
      bootSize = cfg.vm.proxmox.bootSize;
      virtio0 = "${cfg.vm.proxmox.diskStorage}:vm-9999-disk-0";
    } // lib.optionalAttrs (cfg.vm.proxmox.partitionTableType != null) {
      partitionTableType = cfg.vm.proxmox.partitionTableType;
    };
    cloudInit = {
      enable = true;
      defaultStorage = cfg.vm.proxmox.cloudInitStorage;
    };
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    initrd.availableKernelModules = [
      "ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod"
    ];

    kernelModules = [ "kvm-amd" "kvm-intel" ];

    initrd.kernelModules = [
      "virtio_balloon" "virtio_console" "virtio_rng" "virtio_gpu"
    ];
  };

  swapDevices = [ ];
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}

# Configuration for k3s cluster nodes
{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.profiles.k3s-node;
in
{
  options.profiles.k3s-node = {
    enable = mkEnableOption "k3s cluster node";

    role = mkOption {
      type = types.enum [ "init" "server" "agent" ];
      default = "server";
      description = ''
        Node role:
        - init: First server node, initializes the cluster
        - server: Additional server node, joins existing cluster
        - agent: Worker-only node
      '';
    };

    serverAddr = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Address of existing server to join (required for server/agent roles)";
      example = "https://saanthid:6443";
    };

    tokenFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to file containing cluster token";
    };

    clusterDns = mkOption {
      type = types.str;
      default = "10.43.0.10";
      description = "Cluster DNS service IP";
    };

    tlsSans = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional SANs for the k3s TLS certificate";
      example = [ "k3s.example.com" "10.0.0.100" ];
    };

    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional flags to pass to k3s";
    };

    disableTraefik = mkOption {
      type = types.bool;
      default = true;
      description = "Disable built-in Traefik (if using Caddy or other ingress)";
    };

    disableServiceLB = mkOption {
      type = types.bool;
      default = false;
      description = "Disable built-in ServiceLB (Klipper)";
    };

    # VM image generation
    vm = {
      enable = mkEnableOption "VM image generation for this host";

      format = mkOption {
        type = types.enum [ "proxmox" "qcow2" "raw" "vmware" ];
        default = "proxmox";
        description = "VM image format to generate";
      };

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

      # Proxmox-specific options
      proxmox = {
        bios = mkOption {
          type = types.enum [ "seabios" "ovmf" ];
          default = "ovmf";
          description = "BIOS type (seabios or ovmf/UEFI)";
        };

        partitionTableType = mkOption {
          type = types.nullOr (types.enum [ "efi" "hybrid" "legacy" "legacy+gpt" ]);
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
  };

  config = mkIf cfg.enable (mkMerge [
    # Assertions
    {
      assertions = [
        {
          assertion = cfg.role == "init" || cfg.serverAddr != null;
          message = "k3s-node: serverAddr is required for 'server' and 'agent' roles";
        }
      ];
    }

    # k3s service configuration
    {
      services.k3s = {
        enable = true;
        role = if cfg.role == "init" then "server" else cfg.role;
        clusterInit = cfg.role == "init";
        extraFlags = let
          baseFlags = [
            "--cluster-dns=${cfg.clusterDns}"
          ];
          traefikFlags = optionals cfg.disableTraefik [
            "--disable=traefik"
          ];
          serviceLBFlags = optionals cfg.disableServiceLB [
            "--disable=servicelb"
          ];
          tlsFlags = optionals (cfg.role != "agent") (
            [ "--tls-san=${config.networking.hostName}" ]
            ++ map (san: "--tls-san=${san}") cfg.tlsSans
          );
        in baseFlags ++ traefikFlags ++ serviceLBFlags ++ tlsFlags ++ cfg.extraFlags;
      } // optionalAttrs (cfg.serverAddr != null) {
        serverAddr = cfg.serverAddr;
      } // optionalAttrs (cfg.tokenFile != null) {
        tokenFile = cfg.tokenFile;
      };
    }

    # Firewall
    {
      networking.firewall = {
        allowedTCPPorts = [
          6443  # Kubernetes API
          10250 # Kubelet metrics
        ] ++ optionals (cfg.role != "agent") [
          2379  # etcd client
          2380  # etcd peer
        ];

        allowedUDPPorts = [
          8472  # Flannel VXLAN
        ];

        # Trust CNI interfaces
        trustedInterfaces = [ "cni0" "flannel.1" ];
      };
    }

    # Common packages for cluster management
    {
      environment.systemPackages = with pkgs; [
        k9s
        kubectl
        kubernetes-helm
      ];
    }

    # Enable server profile defaults (no sleep/suspend)
    {
      profiles.server.enable = true;
    }

    # QEMU guest agent for VM environments
    {
      services.qemuGuest.enable = mkDefault true;
    }

    # NOTE: Proxmox/QCOW2 image configuration must be set in the host's config
    # because the proxmox-image.nix module conflicts with non-VM hosts.
    # Import (modulesPath + "/virtualisation/proxmox-image.nix") in your host
    # and use the vm.* options from this profile to configure it.
  ]);
}

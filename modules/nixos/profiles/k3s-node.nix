# Configuration for k3s cluster nodes
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.profiles.k3s-node;
in {
  options.profiles.k3s-node = {
    enable = mkEnableOption "k3s cluster node";

    role = mkOption {
      type = types.enum ["init" "server" "agent"];
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
      example = "https://saanthid.local:6443";
    };

    tokenFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to file containing cluster token.
        When profiles.secrets is enabled, defaults to opnix k3s-token.
      '';
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
      example = ["k3s.example.com" "10.0.0.100"];
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
      services.k3s =
        {
          enable = true;
          role =
            if cfg.role == "init"
            then "server"
            else cfg.role;
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
              ["--tls-san=${config.networking.hostName}"]
              ++ map (san: "--tls-san=${san}") cfg.tlsSans
            );
          in
            baseFlags ++ traefikFlags ++ serviceLBFlags ++ tlsFlags ++ cfg.extraFlags;
        }
        // optionalAttrs (cfg.serverAddr != null) {
          serverAddr = cfg.serverAddr;
        }
        // optionalAttrs (cfg.tokenFile != null || config.profiles.secrets.enable) {
          tokenFile =
            if cfg.tokenFile != null
            then cfg.tokenFile
            else config.services.onepassword-secrets.secretPaths.k3sToken;
        };
    }

    # Firewall
    {
      networking.firewall = {
        allowedTCPPorts =
          [
            6443 # Kubernetes API
            10250 # Kubelet metrics
          ]
          ++ optionals (cfg.role != "agent") [
            2379 # etcd client
            2380 # etcd peer
          ];

        allowedUDPPorts = [
          8472 # Flannel VXLAN
        ];

        # Trust CNI interfaces
        trustedInterfaces = ["cni0" "flannel.1"];
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

    # Enable Proxmox VM profile by default for k3s nodes
    {
      profiles.proxmox-vm.enable = mkDefault true;
    }
  ]);
}

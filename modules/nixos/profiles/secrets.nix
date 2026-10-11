{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.profiles.secrets;
  definitions = {
    cloudflareApiKey = {
      key = "Nixos cloudflare acme token";
      owner = "acme";
      group = "acme";
      enable = acmeServices != [];
    };
    homeassistantApiKey = {
      key = "Home Assistant Prometheus";
      owner = "prometheus";
      group = "prometheus";
      enable = config.services.prometheus.enable && config.profiles.observability.observer.enable;
    };
    unifiApiKey = {
      key = "Unifi api key";
      owner = config.services.prometheus.exporters.unpoller.user;
      group = config.services.prometheus.exporters.unpoller.group;
      enable = config.services.prometheus.exporters.unpoller.enable;
    };
    k3sToken = {
      key = "K3s Cluster Token";
      owner = "root";
      group = "root";
      enable = config.profiles.k3s-node.enable && config.profiles.k3s-node.tokenFile == null;
    };
    tranquilPdsEnv = {
      key = "atproto.systems secrets";
      owner = "tranquil-pds";
      group = "tranquil-pds";
      enable = config.profiles.tranquil-pds.enable;
    };
    resendApiKey = {
      key = "Resend API Key";
      owner = "tranquil-pds";
      group = "tranquil-pds";
      enable = config.profiles.tranquil-pds.enable && config.profiles.tranquil-pds.email.fromAddress != null;
    };
  };
  selected = lib.filterAttrs (_: secret: secret.enable) definitions;
  manifest = pkgs.writeText "bitwarden-secrets.json" (builtins.toJSON (
    lib.mapAttrs (name: secret: {
      inherit (secret) owner group;
      key = cfg.names.${name};
    })
    selected
  ));
  cliConfig = (pkgs.formats.toml {}).generate "bws.toml" {
    profiles.default = {
      server_base = cfg.serverUrl;
      state_dir = "/var/lib/bitwarden-secrets";
    };
  };
  acmeServices = lib.mapAttrsToList (name: _: "acme-order-renew-${name}") (
    lib.filterAttrs (_: cert: cert.environmentFile == cfg.paths.cloudflareApiKey) config.security.acme.certs
  );
  consumers =
    acmeServices
    ++ lib.optional definitions.homeassistantApiKey.enable "prometheus"
    ++ lib.optional definitions.unifiApiKey.enable "prometheus-unpoller-exporter"
    ++ lib.optional definitions.k3sToken.enable "k3s"
    ++ lib.optional definitions.tranquilPdsEnv.enable "tranquil-pds";
  dependency = {
    requires = ["bitwarden-secrets.service"];
    after = ["bitwarden-secrets.service"];
  };
  fetcher = pkgs.writeShellApplication {
    name = "fetch-bitwarden-secrets";
    runtimeInputs = [pkgs.python3];
    text = ''
      exec python3 ${./secrets/fetch.py} ${manifest} ${cliConfig} ${lib.getExe pkgs.bws} /run/bitwarden-secrets
    '';
  };
in {
  options.profiles.secrets = with lib; {
    enable = mkEnableOption "Bitwarden Secrets Manager retrieval";
    tokenFile = mkOption {
      type = types.str;
      default = "/etc/bitwarden/access-token";
      description = "Absolute path to a locally provisioned, root-only Bitwarden machine access token. Never use a Nix store path.";
    };
    serverUrl = mkOption {
      type = types.str;
      default = "https://vault.bitwarden.eu";
      description = "Bitwarden server URL; use https://vault.bitwarden.com for the US region.";
    };
    names = mapAttrs (_: secret:
      mkOption {
        type = types.str;
        default = secret.key;
        description = "Unique key of this secret in the Bitwarden machine account's accessible projects.";
      })
    definitions;
    paths = mapAttrs (name: _:
      mkOption {
        type = types.str;
        default = "/run/bitwarden-secrets/current/${name}";
        readOnly = true;
        description = "Runtime path to the managed ${name} secret.";
      })
    definitions;
  };

  config = lib.mkIf (cfg.enable && selected != {}) {
    assertions = [
      {
        assertion = lib.hasPrefix "/" cfg.tokenFile && !(lib.hasPrefix "/nix/store/" cfg.tokenFile);
        message = "profiles.secrets.tokenFile must be an absolute runtime path outside the Nix store.";
      }
    ];
    systemd.services =
      lib.genAttrs consumers (_: dependency)
      // {
        bitwarden-secrets = {
          description = "Fetch service secrets from Bitwarden Secrets Manager";
          wants = ["network-online.target"];
          after = ["network-online.target"];
          wantedBy = ["multi-user.target"];
          restartTriggers = [manifest cliConfig];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = lib.getExe fetcher;
            LoadCredential = ["access-token:${cfg.tokenFile}"];
            RuntimeDirectory = "bitwarden-secrets";
            RuntimeDirectoryMode = "0755";
            RuntimeDirectoryPreserve = "yes";
            StateDirectory = "bitwarden-secrets";
            StateDirectoryMode = "0700";
            UMask = "0077";
            TimeoutStartSec = "120s";
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            NoNewPrivileges = true;
          };
        };
      };
  };
}

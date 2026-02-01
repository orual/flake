#
# Secrets management via 1Password and opnix (brizzbuzz/opnix).
#
# This module configures opnix to pull secrets from 1Password at system
# activation time.
#
{
  config,
  lib,
  ...
}: let
  cfg = config.profiles.secrets;
  opnixCfg = config.services.onepassword-secrets;
in {
  options.profiles.secrets = with lib; {
    enable = mkEnableOption "1Password secrets management via opnix";

    vault = mkOption {
      type = types.str;
      default = "Dev";
      description = "The 1Password vault to pull secrets from";
    };

    tokenFile = mkOption {
      type = types.path;
      default = "/etc/opnix-token";
      description = ''
        Path to the 1Password service account token file.
        This file should be root-readable only (mode 0400).
        Use `sudo opnix token set` to configure.
      '';
    };

    # Expose secret paths for other modules to reference
    paths = {
      cloudflareApiKey = mkOption {
        type = types.str;
        default = opnixCfg.secretPaths.cloudflareApiKey or "/etc/secrets/cloudflare-api-key.key";
        readOnly = true;
        description = "Path to the Cloudflare API key secret";
      };
      homeassistantApiKey = mkOption {
        type = types.str;
        default = opnixCfg.secretPaths.homeassistantApiKey or "/etc/secrets/homeassistant.key";
        readOnly = true;
        description = "Path to the Home Assistant API key secret";
      };
      unifiApiKey = mkOption {
        type = types.str;
        default = opnixCfg.secretPaths.unifiApiKey or "/etc/secrets/unifi-api-key.key";
        readOnly = true;
        description = "Path to the Unifi API key secret";
      };
      k3sToken = mkOption {
        type = types.str;
        default = opnixCfg.secretPaths.k3sToken or "/etc/secrets/k3s-token";
        readOnly = true;
        description = "Path to the K3s cluster token secret";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.onepassword-secrets = {
      enable = true;
      tokenFile = cfg.tokenFile;

      secrets = {
        # Cloudflare API key for ACME DNS validation
        cloudflareApiKey = {
          reference = "op://${cfg.vault}/Nixos cloudflare acme token/credential";
          owner = "acme";
          group = "acme";
          mode = "0400";
        };

        # Home Assistant API key for Prometheus scraping
        homeassistantApiKey = {
          reference = "op://${cfg.vault}/Home Assistant Prometheus/credential";
          owner = "prometheus";
          group = "prometheus";
          mode = "0400";
        };

        # Unifi API key for observability polling
        unifiApiKey = {
          reference = "op://${cfg.vault}/Unifi api key/credential";
          owner = "root";
          group = "root";
          mode = "0400";
        };

        # K3s cluster join token
        k3sToken = {
          reference = "op://${cfg.vault}/K3s Cluster Token/credential";
          owner = "root";
          group = "root";
          mode = "0400";
        };
      };
    };
  };
}

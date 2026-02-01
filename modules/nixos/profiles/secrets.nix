#
# Secrets management via 1Password and opnix.
#
# This module configures opnix to pull secrets from 1Password at system
# activation time. Secrets are stored in ramfs and never persist to disk.
#
{
  config,
  lib,
  ...
}: let
  cfg = config.profiles.secrets;
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
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    opnix = {
      enable = true;
      serviceAccountTokenFile = cfg.tokenFile;

      secrets = {
        # Cloudflare API key for ACME DNS validation
        cloudflare-api-key = {
          source = "{{ op://${cfg.vault}/Cloudflare API Key/credential }}";
          owner = "acme";
          group = "acme";
          mode = "0400";
        };

        # Home Assistant API key for Prometheus scraping
        homeassistant-api-key = {
          source = "{{ op://${cfg.vault}/Home Assistant API Key/credential }}";
          owner = "prometheus";
          group = "prometheus";
          mode = "0400";
        };

        # Unifi API key for observability polling
        unifi-api-key = {
          source = "{{ op://${cfg.vault}/Unifi API Key/credential }}";
          owner = "root";
          group = "root";
          mode = "0400";
        };

        # K3s cluster join token
        k3s-token = {
          source = "{{ op://${cfg.vault}/K3s Cluster Token/credential }}";
          owner = "root";
          group = "root";
          mode = "0400";
        };
      };
    };
  };
}

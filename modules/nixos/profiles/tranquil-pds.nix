# Tranquil PDS profile
#
# Configures a Tranquil PDS (AT Protocol Personal Data Server) with NGINX
# reverse proxy, wildcard ACME TLS via CloudFlare DNS-01, and opnix secrets.
#
# Uses the upstream nixosModules.tranquil-pds from the Tranquil PDS flake
# for the systemd service, PostgreSQL, and binary management.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.profiles.tranquil-pds;
in {
  options.profiles.tranquil-pds = {
    enable = mkEnableOption "Tranquil PDS with NGINX and ACME";

    domain = mkOption {
      type = types.str;
      description = "Public domain for the PDS (e.g., atproto.systems). Wildcard cert will be provisioned for handle subdomains.";
    };

    port = mkOption {
      type = types.int;
      default = 3000;
      description = "Port for the Tranquil PDS to listen on";
    };

    email = {
      fromAddress = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Sender email address for PDS notifications. When null, email is disabled.";
        example = "admin@atproto.systems";
      };

      fromName = mkOption {
        type = types.str;
        default = "Relative State Form";
        description = "Display name in the From header";
      };
    };
  };

  config = mkIf cfg.enable {
    # Tranquil PDS service (via upstream NixOS module)
    services.tranquil-pds = {
      enable = true;
      database.createLocally = true;

      environmentFiles =
        optional config.profiles.secrets.enable
        config.profiles.secrets.paths.tranquilPdsEnv;

      settings = {
        server = {
          hostname = cfg.domain;
          port = cfg.port;
        };
        email = mkIf (cfg.email.fromAddress != null) {
          from_address = cfg.email.fromAddress;
          from_name = cfg.email.fromName;
          sendmail_path = "${pkgs.msmtp}/bin/msmtp";
        };
      };
    };

    # msmtp as sendmail replacement, relaying through Resend SMTP
    programs.msmtp = mkIf (cfg.email.fromAddress != null) {
      enable = true;
      accounts.default = {
        auth = true;
        tls = true;
        host = "smtp.resend.com";
        port = 2465;
        tls_starttls = true;
        from = cfg.email.fromAddress;
        user = "resend";
        passwordeval = "cat ${
          if config.profiles.secrets.enable
          then config.profiles.secrets.paths.resendApiKey
          else "/etc/secrets/resend-api-key"
        }";
      };
    };

    # NGINX reverse proxy with wildcard TLS
    # Frontend is served by the Tranquil PDS backend (frontend.enabled = true),
    # so we proxy everything to the backend. The /xrpc/ path needs special
    # handling for WebSocket connections (firehose) and long timeouts.
    services.nginx = let
      upstream = "http://127.0.0.1:${toString cfg.port}";
      commonVhostConfig = {
        forceSSL = true;
        useACMEHost = cfg.domain;
        extraConfig = ''
          client_max_body_size 10G;
        '';
        locations = {
          # AT Protocol XRPC endpoints - WebSocket support for firehose,
          # long timeouts for streaming, no buffering for real-time data
          "/xrpc/" = {
            proxyPass = upstream;
            extraConfig = ''
              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
              proxy_read_timeout 86400;
              proxy_send_timeout 86400;
              proxy_buffering off;
              proxy_request_buffering off;
            '';
          };

          # OAuth endpoints - extended timeouts for auth flows
          "/oauth/" = {
            proxyPass = upstream;
            extraConfig = ''
              proxy_http_version 1.1;
              proxy_read_timeout 300;
              proxy_send_timeout 300;
            '';
          };

          # Everything else proxied with default settings
          "/" = {
            proxyPass = upstream;
            extraConfig = ''
              proxy_http_version 1.1;
            '';
          };
        };
      };
    in {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts.${cfg.domain} = commonVhostConfig;
      virtualHosts."*.${cfg.domain}" = commonVhostConfig;
    };

    # Wildcard ACME cert via CloudFlare DNS-01
    security.acme = {
      acceptTerms = true;
      defaults.email = mkDefault "orual@nonbinary.computer";
      certs.${cfg.domain} = {
        domain = cfg.domain;
        extraDomainNames = ["*.${cfg.domain}"];
        dnsProvider = "cloudflare";
        environmentFile =
          if config.profiles.secrets.enable
          then config.profiles.secrets.paths.cloudflareApiKey
          else "/etc/secrets/cloudflare-api-key.key";
        group = config.services.nginx.group;
        extraLegoFlags = ["--dns.resolvers=1.1.1.1:53"];
      };
    };

    # Open firewall for HTTP/HTTPS
    networking.firewall.allowedTCPPorts = [80 443];
  };
}

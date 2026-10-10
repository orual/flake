# Bitwarden setup

Secret payloads and tokens must never enter the repository or Nix store. `profiles.secrets` fetches values using `bws` and publishes owner-readable files under `/run/bitwarden-secrets/current/`.

## Provisioning

Create a machine account with **Can read** project access and issue a separate named token per host. Tokens from the same account have identical remote permissions; the module only publishes secrets required by enabled services.

Create Secrets Manager items with unique keys across all accessible projects:

| Option under `profiles.secrets.names` | Default Bitwarden key | Value |
| --- | --- | --- |
| `cloudflareApiKey` | `Nixos cloudflare acme token` | Complete environment file, e.g. `CF_DNS_API_TOKEN=...` |
| `homeassistantApiKey` | `Home Assistant Prometheus` | Raw bearer token |
| `unifiApiKey` | `Unifi api key` | Raw controller credential |
| `k3sToken` | `K3s Cluster Token` | Raw cluster join token |
| `tranquilPdsEnv` | `atproto.systems secrets` | Complete multiline PDS environment file |
| `resendApiKey` | `Resend API Key` | Raw SMTP API key |

Password Manager entries must be transferred into Secrets Manager separately. Values are preserved exactly, including multiline environment files. Missing, duplicate, or empty items fail the fetch without replacing existing files.

Provision a token locally before switching configurations:

```bash
sudo install -d -m 0700 /etc/bitwarden
sudo bash -c 'umask 077; read -r -s -p "Bitwarden access token: " token; printf "\n"; printf "%s" "$token" > /etc/bitwarden/access-token'
```

This keeps the token out of command arguments and shell history. Override `profiles.secrets.tokenFile` with another absolute runtime path if needed. EU accounts must set `profiles.secrets.serverUrl = "https://vault.bitwarden.eu";`.

## Retrieval and rotation

`bitwarden-secrets.service` runs after network readiness. Consumers require successful retrieval before starting. Files are `0400` and published as a complete generation. They are volatile: Bitwarden and network access are required after each reboot. Root-only `/var/lib/bitwarden-secrets` retains the CLI's encrypted authentication session locally.

After changing remote values:

```bash
sudo systemctl restart bitwarden-secrets.service
sudo systemctl restart prometheus.service prometheus-unpoller-exporter.service
```

Only restart enabled consumers. PDS and K3s also need restarting to load changed credentials; ACME reads them on its next renewal. Failed refreshes preserve the previous generation but leave the fetch service failed. Inspect `journalctl -u bitwarden-secrets`, resolve the failure, and retry. The fetcher does not log secret values or upstream CLI error output.

## Desktop SSH and signing

Enable the SSH agent in Bitwarden Desktop settings, unlock the vault, and import the private SSH key matching the existing Git/Jujutsu public signing key. Local sessions use `~/.bitwarden-ssh-agent.sock`; remote sessions retain their forwarded agent. Desktop application startup does not automatically unlock the vault or enable its agent setting.

Check `ssh-add -L` and `ssh -T git@github.com` after deployment. Test a signed commit in a disposable repository with the intended Git identity configured. Existing signing identities are preserved, not rotated.

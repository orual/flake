{
  config,
  lib,
  pkgs,
  ...
}: let
  bitwardenAgent = {
    enable = config.programs.bitwarden.enableSshAgent;
    path = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";
  };
  agentInit = ''
    if [ -z "''${SSH_CONNECTION-}" ] && [ -z "''${SSH_CLIENT-}" ]; then
      export SSH_AUTH_SOCK=${lib.escapeShellArg bitwardenAgent.path}
    fi
  '';
in
  with lib; {
    options.programs.bitwarden.enableSshAgent =
      mkEnableOption "Use the Bitwarden desktop SSH agent";

    config = mkMerge [
      {
        home.packages = with pkgs; [ssh-tools];
        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          settings =
            {
              "Host pattern" = {
                HostName = "pattern";
              };
            }
            // (optionalAttrs bitwardenAgent.enable {
              "*" = {
                ForwardAgent = "yes";
                AddKeysToAgent = "yes";
              };
              "notSsh" = {
                header = ''Match host * exec "test -z \"$SSH_CONNECTION\" && test -z \"$SSH_CLIENT\""'';
                IdentityAgent = bitwardenAgent.path;
              };
            });
        };
      }
      (mkIf bitwardenAgent.enable {
        programs.keychain.enable = mkForce false;
        programs.bash.initExtra = agentInit;
        programs.zsh.initContent = agentInit;
        programs.fish.interactiveShellInit = ''
          if test -z "$SSH_CONNECTION"; and test -z "$SSH_CLIENT"
            set -gx SSH_AUTH_SOCK ${lib.escapeShellArg bitwardenAgent.path}
          end
        '';
      })
    ];
  }

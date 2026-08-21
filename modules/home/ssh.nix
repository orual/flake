{
  config,
  lib,
  pkgs,
  ...
}: let
  _1passwordAgent = {
    enable = config.programs._1password-gui.enableSshAgent;
    path = "${config.home.homeDirectory}/.1password/agent.sock";
  };
in
  with lib; {
    options.programs._1password-gui.enableSshAgent =
      mkEnableOption "Enable 1Password SSH Agent";

    config = {
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
          // (optionalAttrs _1passwordAgent.enable {
            "*" = {
              ForwardAgent = "yes";
              AddKeysToAgent = "yes";
            };
            "notSsh" = {
              header = ''Match host * exec "test -z $SSH_CONNECTION"'';
              IdentityAgent = _1passwordAgent.path;
            };
          });
      };
    };
  }

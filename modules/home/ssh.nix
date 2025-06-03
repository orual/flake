{ config, lib, pkgs, ... }:
let
  _1passwordAgent = {
    enable = config.programs._1password-gui.enableSshAgent;
    path = "${config.home.homeDirectory}/.1password/agent.sock";
  };
in
with lib;
{
  options.programs._1password-gui.enableSshAgent =
    mkEnableOption "Enable 1Password SSH Agent";

  config = {
    home.packages = with pkgs; [ ssh-tools ];
    programs.ssh =
      mkMerge [
        {
          enable = true;
          matchBlocks =
            let
              pattern = "pattern";
              pattern-tailscale = "${pattern}-tailscale";
            in
            {
              # "${pattern}-local" = hm.dag.entryBefore [ pattern-tailscale ] {
              #   match = ''host ${pattern} exec "ping -c1 -W1 -q ${pattern}.local"'';
              #   hostname = "pattern.local";
              # };
              ${pattern-tailscale} = hm.dag.entryBefore [ "notSsh" ] {
                host = "pattern";
                hostname = "pattern";
              };
            };
        }
        (mkIf _1passwordAgent.enable {
          forwardAgent = _1passwordAgent.enable;
          addKeysToAgent = "yes";
          matchBlocks."notSsh" = {
            match = ''host * exec "test -z $SSH_CONNECTION"'';
            extraOptions = {
              IdentityAgent = _1passwordAgent.path;
            };
          };
        })
      ];
  };
}

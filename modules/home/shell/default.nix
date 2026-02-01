#
# Shell configuration.
#
# This module contains configuration for command-line shells (fish, zsh).
# This includes the shell config scripts and prompt configuration for Starship.
#
{
  config,
  lib,
  ...
}:
with lib; {
  imports = [
    ./fish.nix
    ./zsh.nix
    ./starship.nix
  ];

  config = mkMerge [
    {
    }
    (mkIf config.programs.nushell.enable {
      programs.nushell.configFile.text = ''
        let $config = {
          pivot_mode: always
          nonzero_exit_errors: true
          use_ls_colors: true
          table_mode: rounded
        };
      '';
    })
  ];
}

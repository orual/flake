{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.fish;
in
  with lib; {
    config = mkIf cfg.enable {
      programs = {
        # Enable fish integration on other programs
        direnv.enableFishIntegration = true;
        keychain.enableFishIntegration = true;
        starship.enableFishIntegration = true;

        # Set fish as the shell for terminal emulators
        alacritty.settings.shell.program = mkDefault "fish";

        fish = {
          # Fish has excellent built-in autocompletion and syntax highlighting

          shellAliases = {
            # typo corrections
            cagro = "cargo";
            carg = "cargo";
            gti = "git";
          };

          shellInit = ''
            # Add opencode to PATH
            fish_add_path -g /home/orual/.opencode/bin

            # Cargo/Rust
            fish_add_path -g $HOME/.cargo/bin

            # Go
            fish_add_path -g $HOME/go/bin

            # Local bin
            fish_add_path -g $HOME/.local/bin
          '';

          interactiveShellInit = ''
            # Terminal title setting
            function fish_title
              # Show user@host in title for SSH sessions
              if set -q SSH_TTY
                echo (whoami)@(hostname): (prompt_pwd)
              else
                echo (prompt_pwd)
              end
            end

            # SSH detection - fix TERM for compatibility
            if set -q SSH_CLIENT; or set -q SSH_TTY
              set -gx SESSION_TYPE remote/ssh
              set -gx TERM xterm-256color
            else
              switch (ps -o comm= -p $fish_pid 2>/dev/null)
                case 'sshd' '*/sshd'
                  set -gx SESSION_TYPE remote/ssh
                  set -gx TERM xterm-256color
              end
            end

            # Alacritty TERM fix
            # alacritty misuses TERM and sets it to its own name, but does not
            # set TERM_PROGRAM. this causes issues when using software that
            # attempts to detect whether the terminal supports colors using
            # TERM, which is not *really* supposed to be the name of the terminal
            # emulator.
            if string match -q 'alacritty*' $TERM
              set -gx TERM_PROGRAM $TERM
              set -gx TERM xterm-256color
            end
          '';

          functions = {
            # k3d helper from k8s profile
            k3d-import-all = ''
              docker images $argv[1] --format "{{.Repository}}:{{.Tag}}" | xargs k3d image import
            '';
          };
        };
      };
    };
  }

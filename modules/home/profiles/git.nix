{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.profiles.git;
  enable1PasswordSshAgent = config.programs._1password-gui.enableSshAgent;
in
  with lib; {
    options = {
      profiles.git = {
        enable = mkEnableOption "custom git configs";
        user = {
          name = mkOption {
            type = with types; uniq str;
            description = "Git user name";
          };
          email = mkOption {
            type = with types; uniq str;
            description = "Git user email";
          };
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        programs = {
          # GitHub CLI tool
          gh = {
            enable = true;
            # settings = {
            #   # use ssh whenever possible
            #   git_protocol = "ssh";
            #   aliases = {
            #     co = "pr checkout";
            #     pv = "pr view";
            #   };
            # };
          };

          jujutsu = {
            enable = true;
            settings = {
              user = {
                email = cfg.user.email;
                name = "Orual";
              };
              ui = {
                default-command = "log";
                editor = "hx";
              };
              signing = {
                behavior = "drop";
                backend = "ssh";
                backends.ssh.program = "ssh-sign";
                key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGrSMrSEnlsG04W6FxsvSmBST8h5+8ZFA8XBecx7FYLn";
              };
              git = {
                auto-local-bookmark = true;
                sign-on-push = false;
              };
            };
          };
          lazygit = {
            enable = true;
          };
          jjui = {
            enable = true;
          };

          git = {
            enable = true;
            lfs.enable = true;

            # default gitignores for all repos
            ignores = [
              ".cargo/"
              ".direnv/"
            ];

            settings = {
              user = {
                name = cfg.user.name;
                email = cfg.user.email;
                signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGrSMrSEnlsG04W6FxsvSmBST8h5+8ZFA8XBecx7FYLn";
              };

              # aliases
              alias = {
                # list all aliases
                aliases = "config --get-regexp '^alias.'";

                ### short aliases for common commands ###
                co = "checkout";
                ci = "commit";
                rb = "rebase";
                rbct = "rebase --continue";
                please = "push --force-with-lease";
                commend = "commit --amend --no-edit";

                ### nicer commit and branch verbs ###
                squash = "merge --squash";
                # Get the current branch name (not so useful in itself, but used in
                # other aliases)
                branch-name = "!git rev-parse --abbrev-ref HEAD";
                # Push the current branch to the remote "origin", and set it to track
                # the upstream branch
                publish = "!git push -u origin $(git branch-name)";
                # Delete the remote version of the current branch
                unpublish = "!git push origin :$(git branch-name)";
                # sign the last commit
                sign = "commit --amend --reuse-message=HEAD -sS";
                uncommit = "reset --hard HEAD";
                # XXX(orual) AGH THIS DOESNT WORK
                # # Gets the parent of the current branch.
                # parent = ''
                #   show-branch -a \
                #     | grep '\*' \
                #     | grep -v `git rev-parse --abbrev-ref HEAD` \
                #     | head -n1 \
                #     | sed 's/.*\[\(.*\)\].*/\1/' \
                #     | sed 's/[\^~].*//'
                # '';

                ### various git log aliases ###
                # `ls` and `ll` are broken under the latest git for reasons i don't
                # really understand...fortunately i don'tactually use them.
                # ls =
                # "log --pretty=format:'%C(yellow)%h%Cred%d\\ %Creset%s%Cblue\\ [%cn]' --decorate";
                # ll =
                # "log --pretty=format:'%C(yellow)%h%Cred%d\\ %Creset%s%Cblue\\ [%cn]' --decorate --numstat";
                lt = "log --graph --oneline --decorate --all";
                summarize-branch = ''
                  log --pretty=format:'* %h %s%n%n%w(72,2,2)%bz' --decorate
                '';
                lol = "log --graph --decorate --pretty=oneline --abbrev-commit";
                lola = "log --graph --decorate --pretty=oneline --abbrev-commit --all";

                lg = "log --color --graph --pretty=format:'%Cred%h %Cgreen%>(9,trunc)%ar %C(bold blue)%<(12,trunc)%an%Creset - %s%C(auto)%+d' --abbrev-commit --";
                lgf = "log --color --graph --pretty=format:'%Cred%h %Cgreen%>(9,trunc)%ar %C(bold blue)%<(12,trunc)%an%Creset - %C(cyan)%s%C(auto)%+d%+b' --abbrev-commit --";
                lgm = "log --color --graph --pretty=format:'%Cred%h%Creset %<|(50,trunc)%s%C(auto)%+d' --abbrev-commit --";

                ### status ###
                st = "status --short --branch";
                stu = "status -uno";

                pr = "!pr() { git fetch origin pull/$1/head:pr-$1; git checkout pr-$1; }; pr";
              };

              # use rebase in `git pull` to avoid gross merge commits.
              pull.rebase = true;
              push.autoSetupRemote = true;
              # when fetching, prune unreachable objects in the local repository.
              fetch.prune = true;
              # differentiate between moved and added lines in diffs
              diff.colorMoved = "zebra";
              core = {
                # Assembly-style commit message comments (`;` as the comment delimiter).
                # Why use `;`?
                # - The default character, `#`, conflicts with both Markdown headings
                #   and with GitHub issue links beginning a line (which I need to be
                #   able to use in commit messages).
                # - `*` conflicts with Markdown lists
                # - Git only supports a single character comment delimiter, so C-style
                #   line comments (`//`) are out...
                # - I can't think of any compelling reason to begin a line with `;`...
                commentchar = ";";
                editor = "hx";
              };
              extensions = {
                objectformat = "sha256";
              };
              # Set the default branch name to `main`.
              init.defaultBranch = "main";
              # use 1password to manage commit signing if available
              gpg = {
                format = lib.mkForce "ssh";
                # "ssh".program = lib.mkIf enable1PasswordSshAgent
                #   "${pkgs._1password-gui}/bin/op-ssh-sign";
              };
              commit.gpgsign = true;
            };
          };
        };
      }
      (mkIf enable1PasswordSshAgent (
        let
          signingScript = with pkgs;
            writeShellApplication {
              name = "ssh-sign";
              runtimeInputs = [_1password-gui];
              # If we're not in a SSH session, use `op-ssh-sign` to sign commits.
              # Otherwise, use `ssh-keygen` to sign commits with a forwarded key
              # in `SSH_AUTH_SOCK`.
              text = ''
                if [ -z "''${SSH_CONNECTION-}" ]; then
                  exec "op-ssh-sign" "$@"
                else
                  exec ssh-keygen "$@"
                fi
              '';
            };
        in {
          home.packages = [signingScript];
          programs.git.settings.gpg."ssh".program = "ssh-sign";
        }
      ))
    ]);
  }

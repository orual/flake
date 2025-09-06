{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.profiles.devtools;
in {
  imports = [./gdb-dashboard.nix];

  options.profiles.devtools = with lib; {
    enable = mkEnableOption "Profile for development tools";
    enablePython = mkEnableOption "Enable Python";
  };

  config = with lib;
    mkMerge [
      (mkIf cfg.enable {
        home.packages = with pkgs; [
          vscode
          # ## toolchains ###
          rustup
          # clang

          ### devtools ###
          # llvmPackages.bintools
          # use lldb from unstable, since it's on a newer version
          lldb
          # the good `time`, not the shell builtin
          time
          psmisc
          valgrind
          gnumake42

          # `just` --- a command runner
          just
          # V I B E C O D I N G
          claude-code-latest
          #opencode-latest
          # TURNS OUT THIS HAS TO BE IN SYSTEMPACKAGES LOL
          # # xfel --- FEL tools for Allwinner SoCs
          # xfel
          colordiff

          # docker stuff
          docker-compose
          docker-credential-helpers

          # asciidoc
          asciidoctor-with-extensions

          # stuff for decoding various things
          hwloc
          dmidecode

          ### networking stuff ###
          nghttp2

          # disk imager
          caligula

          #-- cargo tools
          cargo-generate
          cargo-sync-readme
          cargo-release
          cargo-udeps
          cargo-embassy

          #-- latest glasgow
          #glasgow-latest

          #-- embedded rust debugging
          probe-rs

          #-- espressif rust tools
          espup # not properly sandboxed/pure, will need manual install

          # STM32 flasher
          stlink-gui
          #stm32cubeprog
          # serial terminal
          minicom
          # rom programmer
          minipro
          # stm32cubemx
          #
          kicad
        ];

        home.sessionPath = [
          "$HOME/.config/Code/User/globalStorage/ms-vscode-remote.remote-containers/cli-bin"
        ];

        # Dev tools with extra configuration
        programs = {
          zed-editor = {
            enable = config.profiles.desktop.enable;
            package = pkgs.zed-editor;
          };
          # Nice terminal UI for gdb
          gdb.dashboard = {
            enable = mkDefault true;
            enablePygments = mkDefault true;

            extraConfig = ''
              dashboard -layout assembly breakpoints expressions history memory registers source stack threads variables
              dashboard registers -style column-major True
              dashboard registers -style list 'rax rbx rcx rdx rsi rdi rbp rsp r8 r9 r10 r11 r12 r13 r14 r15 rip eflags cs ss ds es fs gs fs_base gs_base k_gs_base cr0 cr2 cr3 cr4 cr8 efe msxr'
            '';
          };
          helix.enable = mkDefault true;

          jq.enable = mkDefault true;

          direnv = {
            enable = mkDefault true;
            nix-direnv.enable = mkDefault true;
          };
        };
      })

      (mkIf cfg.enablePython {
        home.packages = with pkgs; [
          python312
          python312Packages.pip
        ];
      })

      (mkIf config.programs.zed-editor.enable {
        stylix.targets.zed.enable = false;
        # the Nix package for zed calls the binary "zeditor", which is annoying
        home.shellAliases = {
          zed = "${config.programs.zed-editor.package}/bin/zeditor";
        };
        # Make Zed the default editor.
        home.sessionVariables.EDITOR = mkForce "${config.programs.zed-editor.package}/bin/zeditor --wait";
      })
      (mkIf config.programs.helix.enable {
        programs.helix = {
          package = pkgs.helix;
          extraPackages = with pkgs; [
            nil
            alejandra
            rust-analyzer
            rustfmt
            helix-gpt
          ];
          settings = {
            theme = lib.mkDefault "rose-pine";
            editor = {
              cursorline = true;
              bufferline = "multiple";
              color-modes = true;
              lsp.display-messages = true;
              lsp.display-inlay-hints = true;
              lsp.display-signature-help-docs = true;
              lsp.snippets = true;
              lsp.goto-reference-include-declaration = true;
              cursor-shape = {
                insert = "bar";
                normal = "block";
                select = "underline";
              };
              indent-guides = {
                render = true;
              };
              statusline = {
                left = [
                  "mode"
                  "spinner"
                  "spacer"
                  "version-control"
                ];
                center = [
                  "file-name"
                  "read-only-indicator"
                  "file-modification-indicator"
                ];
                right = [
                  "diagnostics"
                  "selections"
                  "register"
                  "position"
                  "file-encoding"
                  "file-line-ending"
                  "file-type"
                ];
                separator = "│";
                mode.normal = "NOR";
                mode.insert = "INS";
                mode.select = "SEL";
              };
            };
          };
        };
      })
    ];
}

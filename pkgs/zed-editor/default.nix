{
  lib,
  rustPlatform,
  fetchFromGitHub,
  cmake,
  copyDesktopItems,
  curl,
  perl,
  pkg-config,
  protobuf,
  fontconfig,
  freetype,
  libgit2,
  openssl,
  sqlite,
  zlib,
  zstd,
  alsa-lib,
  libxkbcommon,
  wayland,
  libglvnd,
  xorg,
  stdenv,
  makeFontsConf,
  vulkan-loader,
  envsubst,
  nix-update-script,
  cargo-about,
  versionCheckHook,
  buildFHSEnv,
  cargo-bundle,
  git,
  apple-sdk_15,
  darwinMinVersionHook,
  makeBinaryWrapper,
  makeWrapper,
  makeDesktopItem,
  nodejs,
  libGL,
  libX11,
  libXext,
  livekit-libwebrtc,
  testers,
  writableTmpDirAsHomeHook,
  python3,
  withGLES ? false,
  buildRemoteServer ? true,
  zed-editor,
}:
assert withGLES -> stdenv.hostPlatform.isLinux; let
  executableName = "zeditor";
  # Based on vscode.fhs
  # Zed allows for users to download and use extensions
  # which often include the usage of pre-built binaries.
  # See #309662
  #
  # buildFHSEnv allows for users to use the existing Zed
  # extension tooling without significant pain.
  fhs = {
    zed-editor,
    additionalPkgs ? pkgs: [],
  }:
    buildFHSEnv {
      # also determines the name of the wrapped command
      name = executableName;

      # additional libraries which are commonly needed for extensions
      targetPkgs = pkgs:
        (with pkgs; [
          # ld-linux-x86-64-linux.so.2 and others
          glibc
        ])
        ++ additionalPkgs pkgs;

      # symlink shared assets, including icons and desktop entries
      extraInstallCommands = ''
        ln -s "${zed-editor}/share" "$out/"
      '';

      runScript = "${zed-editor}/bin/${executableName}";

      passthru = {
        inherit executableName;
        inherit (zed-editor) pname version;
      };

      meta =
        zed-editor.meta
        // {
          description = ''
            Wrapped variant of ${zed-editor.pname} which launches in a FHS compatible environment.
            Should allow for easy usage of extensions without nix-specific modifications.
          '';
        };
    };

  gpu-lib =
    if withGLES
    then libglvnd
    else vulkan-loader;
in
  rustPlatform.buildRustPackage (finalAttrs: {
    pname = "zed-editor";
    version = "0.199.10-wayland-touch";

    src = fetchFromGitHub {
      owner = "orual";
      repo = "zed";
      rev = "41c0a0bce67958ba362d982eaaaf7f6e36ab516e";
      hash = "sha256-euBC+3ifxX3pL2QWFnbBr/7Ho3cQcH4X3Ok4BeRum18=";
    };

    patches = [
      ./0001-linux-linker.patch
    ];

    postPatch = ''
            # Remove duplicate reqwest entry from Cargo.lock
            ${python3}/bin/python3 -c "
      import sys
      with open('Cargo.lock', 'r') as f:
          lines = f.readlines()

      # Find and remove the duplicate reqwest 0.12.15 from crates.io
      in_package = False
      start_line = -1
      for i, line in enumerate(lines):
          if line.strip() == '[[package]]':
              in_package = True
              start_line = i
          elif in_package and line.strip() == 'name = \"reqwest\"':
              # Check if this is the crates.io version (not the git version)
              if i+1 < len(lines) and lines[i+1].strip() == 'version = \"0.12.15\"':
                  if i+2 < len(lines) and 'crates.io' in lines[i+2]:
                      # Found the duplicate, now find the end of this package block
                      end_line = i
                      for j in range(i, len(lines)):
                          if j > i and (lines[j].strip() == \'\' or lines[j].strip() == '[[package]]'):
                              end_line = j
                              break
                      print(f'Removing duplicate reqwest at lines {start_line+1}-{end_line}')
                      del lines[start_line:end_line]
                      break
              in_package = False

      with open('Cargo.lock', 'w') as f:
          f.writelines(lines)
      "
    '';

    cargoHash = "sha256-PM1njw9RjPqyUrAnmpSTAUuW/g0UEYHoCf7xYLelGNA=";

    nativeBuildInputs =
      [
        cmake
        copyDesktopItems
        curl
        perl
        pkg-config
        protobuf
        rustPlatform.bindgenHook
        cargo-about
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [makeWrapper];

    dontUseCmakeConfigure = true;

    buildInputs =
      [
        curl
        fontconfig
        freetype
        libgit2
        openssl
        sqlite
        zlib
        zstd
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [
        alsa-lib
        libxkbcommon
        wayland
        xorg.libxcb
      ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        apple-sdk_15
        darwinMinVersionHook
      ];

    cargoBuildFlags =
      [
        "--package=zed"
      ]
      ++ lib.optional buildRemoteServer "--package=remote_server";

    buildFeatures = ["gpui/runtime_shaders"];

    env = {
      ZSTD_SYS_USE_PKG_CONFIG = true;
      LIBSQLITE3_SYS_USE_PKG_CONFIG = true;
      LIVEKIT_WEBRTC_DYLIB_PATH = "${livekit-libwebrtc}/lib";
      LIVEKIT_WEBRTC_PKG_CONFIG_PATH = "${livekit-libwebrtc}/lib/pkgconfig";
    };

    RUSTFLAGS =
      if withGLES
      then "--cfg gles"
      else "";
    gpu-lib =
      if withGLES
      then libglvnd
      else vulkan-loader;

    doCheck = false;
    checkPhase = ''
      runHook preCheck
      HOME=$(mktemp -d) cargo-about init
      HOME=$(mktemp -d) cargo-about generate -c about.toml --fail -o target/licenses.html about.hbs
      runHook postCheck
    '';

    postInstall =
      ''
        cd ${
          if stdenv.hostPlatform.isDarwin
          then "target/release"
          else "target/release"
        }
        mv zed ${executableName}
        install -D ${executableName} $out/bin/${executableName}
      ''
      + lib.optionalString buildRemoteServer ''
        mv target/release/remote_server $out/bin/remote_server
      '';

    postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
      patchelf --add-rpath ${gpu-lib}/lib $out/bin/${executableName}
      patchelf --add-rpath ${wayland}/lib $out/bin/${executableName}
      wrapProgram $out/bin/${executableName} \
        --prefix PATH : ${lib.makeBinPath [nodejs]} \
        --suffix PATH : ${lib.makeBinPath [git]} \
        --prefix LD_LIBRARY_PATH : ${libGL}/lib \
        --prefix LD_LIBRARY_PATH : ${libX11}/lib \
        --prefix LD_LIBRARY_PATH : ${libXext}/lib
    '';

    desktopItems = [
      (makeDesktopItem {
        name = "dev.zed.Zed";
        exec = executableName;
        tryExec = executableName;
        icon = "zed";
        comment = "A high-performance, multiplayer code editor.";
        desktopName = "Zed";
        genericName = "Text Editor";
        categories = [
          "Utility"
          "TextEditor"
          "Development"
        ];
        keywords = ["zed"];
        mimeTypes = [
          "text/plain"
          "application/x-zerosize"
          "x-scheme-handler/zed"
        ];
        startupNotify = true;
        terminal = false;
        type = "Application";
        actions = {
          NewWorkspace = {
            name = "Open a new workspace";
            exec = "${executableName} --new %U";
          };
        };
      })
    ];

    passthru = {
      updateScript = nix-update-script {
        extraArgs = [
          "--version-regex"
          "^v(?!.*(?:-pre|0\\.999999\\.0|0\\.9999-temporary)$)(.+)$"
        ];
      };
      fhs = fhs {zed-editor = finalAttrs.finalPackage;};
      fhsWithPackages = f:
        fhs {
          zed-editor = finalAttrs.finalPackage;
          additionalPkgs = f;
        };
      tests = {
        version = lib.optionalAttrs stdenv.hostPlatform.isLinux (
          testers.testVersion {package = finalAttrs.finalPackage;}
        );
        remoteServerVersion = lib.optionalAttrs buildRemoteServer (
          testers.testVersion {
            package = finalAttrs.finalPackage.remote_server;
            command = "remote_server version";
          }
        );
      };
    };

    meta = {
      description = "High-performance, multiplayer code editor from the creators of Atom and Tree-sitter";
      longDescription = ''
        High-performance, multiplayer code editor from the creators of Atom and Tree-sitter.
        With built-in AI features, you can generate, transform, and analyze code alongside your team.
      '';
      homepage = "https://zed.dev";
      changelog = "https://github.com/zed-industries/zed/releases/tag/v${finalAttrs.version}";
      license = lib.licenses.gpl3Only;
      maintainers = with lib.maintainers; [
        GaetanLepage
        niklaskorz
      ];
      mainProgram = executableName;
      platforms = lib.platforms.linux ++ lib.platforms.darwin;
    };
  })

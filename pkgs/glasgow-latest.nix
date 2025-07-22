{
  lib,
  python311,
  python311Packages,
  fetchFromGitHub,
  sdcc,
  yosys,
  icestorm,
  nextpnr,
  unstableGitUpdater,
  pdm,
}: let
  python = python311;
  stdenv = python311Packages.stdenv;
in
  python311Packages.buildPythonApplication rec {
    pname = "glasgow";
    version = "0-unstable-2025-07-18";
    # from `pdm show`
    realVersion = let
      tag = builtins.elemAt (lib.splitString "-" version) 0;
      rev = lib.substring 0 7 src.rev;
    in "${tag}.1.dev2373+g${rev}";

    pyproject = true;

    src = fetchFromGitHub {
      owner = "GlasgowEmbedded";
      repo = "glasgow";
      rev = "1d757d3996a1a0906bd7fac14a7a056afb057092";
      sha256 = "sha256-4IRgdPikfTgM1mmIK6pG+dJfcpVEWDx5zFkKliuVs3k=";
    };

    nativeBuildInputs = [
      python311Packages.pdm-backend
      sdcc
    ];

    propagatedBuildInputs = with python311Packages; [
      typing-extensions
      amaranth
      packaging
      platformdirs
      fx2
      libusb1
      pyvcd
      aiohttp
      cobs
      importlib-resources
    ];

    nativeCheckInputs = [
      python311Packages.unittestCheckHook
      yosys
      icestorm
      nextpnr
    ];

    enableParallelBuilding = true;

    __darwinAllowLocalNetworking = true;

    preBuild = ''
      make -C firmware LIBFX2=${python311Packages.fx2}/share/libfx2
      cp firmware/glasgow.ihex software/glasgow
      cd software
      export PDM_BUILD_SCM_VERSION="${realVersion}"
    '';

    # installCheck tries to build_ext again
    doInstallCheck = false;

    postInstall = ''
      mkdir -p $out/etc/udev/rules.d
      cp $src/config/*.rules $out/etc/udev/rules.d
    '';

    preCheck = ''
      export PYTHONWARNINGS="ignore::DeprecationWarning"
      # tests attempt to cache bitstreams
      # for linux:
      export XDG_CACHE_HOME=$TMPDIR
      # for darwin:
      export HOME=$TMPDIR
    '';

    makeWrapperArgs = [
      "--set"
      "YOSYS"
      "${yosys}/bin/yosys"
      "--set"
      "ICEPACK"
      "${icestorm}/bin/icepack"
      "--set"
      "NEXTPNR_ICE40"
      "${nextpnr}/bin/nextpnr-ice40"
    ];

    passthru.updateScript = unstableGitUpdater {
      hardcodeZeroVersion = true;
    };

    meta = with lib; {
      description = "Software for Glasgow, a digital interface multitool";
      homepage = "https://github.com/GlasgowEmbedded/Glasgow";
      license = licenses.bsd0;
      maintainers = with maintainers; [thoughtpolice];
      mainProgram = "glasgow";
    };
  }

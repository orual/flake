{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.profiles.voxtype;
  packages = inputs.voxtype.packages.${pkgs.stdenv.hostPlatform.system};
  models = import ./models.nix {inherit pkgs lib;};
  meetingModel =
    if cfg.meetings.model == "cohere"
    then models.cohere
    else if cfg.meetings.model == "parakeet-tdt-int8"
    then models.parakeetTdtInt8
    else models.parakeetTdt;
  meetingBinary = pkgs.symlinkJoin {
    name = "voxtype-meeting-binary";
    paths = [
      (packages.voxtype-onnx-unwrapped.overrideAttrs (old: {
        buildFeatures = old.buildFeatures ++ lib.optional (cfg.meetings.diarization == "ml") "ml-diarization";
      }))
    ];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/voxtype \
        --prefix PATH : ${lib.makeBinPath [pkgs.pulseaudio]} \
        --set ORT_DYLIB_PATH ${pkgs.onnxruntime}/lib/libonnxruntime.so \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [pkgs.onnxruntime]}
    '';
  };
  meetingConfig = (pkgs.formats.toml {}).generate "voxtype-meeting.toml" ({
      engine =
        if cfg.meetings.model == "cohere"
        then "cohere"
        else "parakeet";
      state_file = "auto";
      hotkey.enabled = false;
      osd.enabled = false;
      audio = {
        device = "default";
        sample_rate = 16000;
      };
      meeting = {
        enabled = true;
        chunk_duration_secs = 30;
        retain_audio = false;
        audio = {
          mic_device = "default";
          loopback_device = "@DEFAULT_MONITOR@";
        };
        diarization = {
          enabled = true;
          backend = cfg.meetings.diarization;
        };
        summary.backend = "disabled";
      };
    }
    // (
      if cfg.meetings.model == "cohere"
      then {
        cohere = {
          model = "${meetingModel}";
          on_demand_loading = true;
        };
      }
      else {
        parakeet = {
          model = "${meetingModel}";
          streaming = false;
          on_demand_loading = true;
        };
      }
    ));
  meetingLauncher = pkgs.writeShellApplication {
    name = "voxtype-meeting";
    runtimeInputs = [meetingBinary];
    text = ''
      desktop_runtime="''${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR must be set}"
      export PULSE_SERVER="''${PULSE_SERVER:-unix:$desktop_runtime/pulse/native}"
      export PIPEWIRE_RUNTIME_DIR="''${PIPEWIRE_RUNTIME_DIR:-$desktop_runtime}"
      export XDG_RUNTIME_DIR="$desktop_runtime/voxtype-meeting"
      mkdir -p "$XDG_RUNTIME_DIR"
      chmod 700 "$XDG_RUNTIME_DIR"
      if [[ $# -eq 0 || "$1" == daemon ]]; then
        exec voxtype --config ${meetingConfig} daemon
      fi
      exec voxtype --config ${meetingConfig} meeting "$@"
    '';
  };
in {
  options.profiles.voxtype = {
    enable = lib.mkEnableOption "local voice dictation and meeting transcription";
    amdAcceleration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use MIGraphX for dictation on a supported AMD GPU.";
    };
    dictation = {
      engine = lib.mkOption {
        type = lib.types.enum ["parakeet" "whisper-vulkan"];
        default = "parakeet";
        description = "Use Parakeet streaming or Whisper with Vulkan GPU acceleration.";
      };
      whisperModel = lib.mkOption {
        type = lib.types.str;
        default = "large-v3-turbo";
        description = "Whisper model fetched by the upstream Home Manager module when using whisper-vulkan.";
      };
    };
    meetings = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install the isolated meeting launcher and its selected model.";
      };
      model = lib.mkOption {
        type = lib.types.enum ["cohere" "parakeet-tdt" "parakeet-tdt-int8"];
        default = "parakeet-tdt";
        description = "Meeting model: Cohere FP16 or full-precision Parakeet TDT v3.";
      };
      diarization = lib.mkOption {
        type = lib.types.enum ["simple" "ml"];
        default = "simple";
        description = "Attribute speakers by audio source or local ML speaker embeddings.";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.amdAcceleration || pkgs.stdenv.hostPlatform.isx86_64;
          message = "profiles.voxtype.amdAcceleration requires an x86_64 host with a supported AMD GPU.";
        }
      ];
      home.packages = [packages.osd-gtk4 pkgs.dotool];
      programs.voxtype = {
        enable = true;
        engine =
          if cfg.dictation.engine == "whisper-vulkan"
          then "whisper"
          else "parakeet";
        package =
          if cfg.dictation.engine == "whisper-vulkan"
          then packages.vulkan
          else if cfg.amdAcceleration
          then packages.onnx-migraphx
          else packages.onnx;
        model =
          if cfg.dictation.engine == "whisper-vulkan"
          then {
            name = cfg.dictation.whisperModel;
          }
          else {
            path = "${models.unified}";
          };
        service.enable = true;
        settings = {
          hotkey.enabled = false;
          parakeet = lib.mkIf (cfg.dictation.engine == "parakeet") {
            streaming = true;
            streaming_chunk_secs = 0.56;
            streaming_left_context_secs = 5.6;
            streaming_right_context_secs = 0.56;
          };
          whisper = lib.mkIf (cfg.dictation.engine == "whisper-vulkan") {
            language = "en";
            streaming = false;
            on_demand_loading = true;
          };
          output = {
            mode = "type";
            shift_enter_newlines = true;
            driver_order = ["dotool" "clipboard"];
            fallback_to_clipboard = true;
          };
          audio.max_duration_secs = 120;
          text.smart_auto_submit = true;
          streaming = {
            interval_secs = 0.5;
            max_buffer_secs = 30.0;
            partial_min_words = 1;
            type_partials = true;
            revision_mode = true;
          };
        };
      };
    }
    (lib.mkIf cfg.meetings.enable {
      home.packages = [meetingLauncher];
      xdg.configFile."voxtype/meeting.toml".source = meetingConfig;
    })
  ]);
}

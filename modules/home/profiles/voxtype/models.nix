{
  pkgs,
  lib,
}: let
  fetchModel = name: repo: revision: files:
    pkgs.linkFarm name (lib.mapAttrsToList (target: file: {
        name = target;
        path = pkgs.fetchurl {
          url = "https://huggingface.co/${repo}/resolve/${revision}/${file.path or target}";
          sha256 = file.sha256;
        };
      })
      files);
in {
  unified = fetchModel "parakeet-unified-en-0.6b" "bobNight/parakeet-unified-en-0.6b-onnx" "09e9060322d99c5f070010724786e6ee090fd51d" {
    "encoder.onnx".sha256 = "50083dd0b2af503b87ea8fcf9fd7d7dc15dda3130e4113017c8b37ed00418ba4";
    "encoder.onnx.data".sha256 = "c054b2932ee13aa39ed84982a399822f3193311fb6fd8e1e204566722614bd87";
    "decoder_joint.onnx".sha256 = "64648c91935ea4819e9c31ea8a20f011d3b1c960be3861cb8bc74df0259cd998";
    "tokenizer.model".sha256 = "07d4e5a63840a53ab2d4d106d2874768143fb3fbdd47938b3910d2da05bfb0a9";
    "vocab.txt".sha256 = "ae61c9b743cb47c04ce6fb130444210646ed0f40c953c77ee1855185960af94f";
  };
  cohere = fetchModel "cohere-transcribe-fp16" "onnx-community/cohere-transcribe-03-2026-ONNX" "31b1c6211c9000d76b077ddd23b74c9090badeba" {
    "encoder_model.onnx" = {
      path = "onnx/encoder_model_fp16.onnx";
      sha256 = "155046e82c022bb37a43ca13c0d7837bc0fd046b152d578d8312fc1e10567e8a";
    };
    "encoder_model_fp16.onnx_data" = {
      path = "onnx/encoder_model_fp16.onnx_data";
      sha256 = "7c309fd84aca668770dbf8e0370ca3b0e523ac915b368d7dea284702cd3847cd";
    };
    "encoder_model_fp16.onnx_data_1" = {
      path = "onnx/encoder_model_fp16.onnx_data_1";
      sha256 = "772b2bbf50fdfc248df832333f06e22fc6f9d41316abbea72b82526f72a6050f";
    };
    "decoder_model_merged.onnx" = {
      path = "onnx/decoder_model_merged_fp16.onnx";
      sha256 = "88e272acb7b436e7ed01c43c2c4d63a5d93f1c3d324fff6329b4c6538743563f";
    };
    "decoder_model_merged_fp16.onnx_data" = {
      path = "onnx/decoder_model_merged_fp16.onnx_data";
      sha256 = "4aead3d7d2a04a84001690d992945bba8b45a1082db6b0812c3f352189323e29";
    };
    "tokenizer.json".sha256 = "e263c0ba13be0f0803705b002756908f84efc6e75a4c273231a01c4371908a2b";
    "tokenizer_config.json".sha256 = "4c8fec06c9e195180299db3baa370d0090be68ec611cadcf54c43217a306ca05";
    "config.json".sha256 = "09cec8fb9a44e8c278b23efd2b8afbf29e560c2eb2b5c1a6b448d8b33a6632bf";
    "generation_config.json".sha256 = "dd575639e03b2651c2ecad52c1a51e6126d2a516780cfe85e7b4517f05bd9754";
    "processor_config.json".sha256 = "b362db9538c695d84be46232025d8488423bd47a0fa3412d6019ec32c0615940";
  };
  parakeetTdtInt8 = fetchModel "parakeet-tdt-0.6b-v3-int8" "istupakov/parakeet-tdt-0.6b-v3-onnx" "8f23f0c03c8761650bdb5b40aaf3e40d2c15f1ce" {
    "encoder-model.int8.onnx".sha256 = "6139d2fa7e1b086097b277c7149725edbab89cc7c7ae64b23c741be4055aff09";
    "decoder_joint-model.int8.onnx".sha256 = "eea7483ee3d1a30375daedc8ed83e3960c91b098812127a0d99d1c8977667a70";
    "vocab.txt".sha256 = "d58544679ea4bc6ac563d1f545eb7d474bd6cfa467f0a6e2c1dc1c7d37e3c35d";
    "config.json".sha256 = "666903c76b9798caf2c210afd4f6cd60b08a8dbf9800ec8d7a3bc0d2148ac466";
  };
  parakeetTdt = fetchModel "parakeet-tdt-0.6b-v3" "istupakov/parakeet-tdt-0.6b-v3-onnx" "8f23f0c03c8761650bdb5b40aaf3e40d2c15f1ce" {
    "encoder-model.onnx".sha256 = "98a74b21b4cc0017c1e7030319a4a96f4a9506e50f0708f3a516d02a77c96bb1";
    "encoder-model.onnx.data".sha256 = "9a22d372c51455c34f13405da2520baefb7125bd16981397561423ed32d24f36";
    "decoder_joint-model.onnx".sha256 = "e978ddf6688527182c10fde2eb4b83068421648985ef23f7a86be732be8706c1";
    "vocab.txt".sha256 = "d58544679ea4bc6ac563d1f545eb7d474bd6cfa467f0a6e2c1dc1c7d37e3c35d";
    "config.json".sha256 = "666903c76b9798caf2c210afd4f6cd60b08a8dbf9800ec8d7a3bc0d2148ac466";
  };
}

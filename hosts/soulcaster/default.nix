{ nixos-hardware, lanzaboote, ... }:
{
  system = "aarch64-linux";

  modules = [];

  home.modules = [ ./home.nix ];
}

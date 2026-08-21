{ nixos-hardware, lanzaboote, ... }:
{
  system = "aarch64-linux";



  home.modules = [ ./home.nix ];
}

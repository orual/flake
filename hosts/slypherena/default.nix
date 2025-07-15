{ nixos-hardware, lanzaboote, ... }: {
  system = "x86_64-linux";

  modules = [
    ./configuration.nix
    nixos-hardware.nixosModules.framework-12-13th-gen-intel
    #lanzaboote.nixosModules.lanzaboote
  ];

  home.modules = [ ./home.nix ];
}

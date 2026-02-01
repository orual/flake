{ ... }: {
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "24.11";

  networking.hostName = "saanthid";

  profiles.k3s-node = {
    enable = true;
    role = "server";
    serverAddr = "https://chasmfiend:6443";
    # tokenFile = "/etc/secrets/k3s-token";  # TODO: set up with 1password

    # Additional TLS SANs for cluster access
    tlsSans = [
      "k3s.home.nonbinary.computer"
      "saanthid.local"
    ];

    # VM image generation for Proxmox (on booskie-laptop)
    vm = {
      enable = true;
      format = "proxmox";
      cores = 2;
      memory = 4096;

      proxmox = {
        additionalSpace = "15G";
        cloudInitStorage = "local-zfs";
        diskStorage = "local-zfs";
      };
    };
  };
}

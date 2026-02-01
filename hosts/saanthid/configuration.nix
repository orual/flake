{ ... }: {
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "24.11";

  networking.hostName = "saanthid";

  profiles.k3s-node = {
    enable = true;
    role = "init";
    # tokenFile = "/etc/secrets/k3s-token";  # TODO: set up with 1password

    # Additional TLS SANs for cluster access
    tlsSans = [
      "k3s.home.nonbinary.computer"
      "saanthid.local"
    ];

    # VM image generation for Proxmox
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

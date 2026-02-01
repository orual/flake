{ ... }: {
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "24.11";

  networking.hostName = "tai-na";

  # 1Password secrets management
  profiles.secrets.enable = true;

  profiles.k3s-node = {
    enable = true;
    role = "server";
    serverAddr = "https://chasmfiend:6443";
    # Token automatically provided by opnix via profiles.secrets

    # Additional TLS SANs for cluster access
    tlsSans = [
      "k3s.home.nonbinary.computer"
      "tai-na.local"
    ];

    # VM image generation for Proxmox (on booskie-host - biggest node)
    vm = {
      enable = true;
      format = "proxmox";
      cores = 4;
      memory = 8192;

      proxmox = {
        additionalSpace = "30G";
        cloudInitStorage = "local-zfs";
        diskStorage = "local-zfs";
      };
    };
  };
}

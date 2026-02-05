{...}: {
  imports = [./hardware-configuration.nix];

  system.stateVersion = "24.11";

  networking.hostName = "chasmfiend";

  # 1Password secrets management
  profiles.secrets.enable = true;

  profiles.k3s-node = {
    enable = true;
    role = "init";
    # Token automatically provided by opnix via profiles.secrets

    # Additional TLS SANs for cluster access
    tlsSans = [
      "k3s.home.nonbinary.computer"
      "chasmfiend.local"
    ];

    # VM image generation for Proxmox (on archive - smaller node)
    vm = {
      enable = true;
      format = "proxmox";
      cores = 2;
      memory = 2048;

      proxmox = {
        additionalSpace = "10G";
        cloudInitStorage = "local-zfs";
        diskStorage = "local-zfs";
      };
    };
  };
}

{...}: {
  system.stateVersion = "24.11";

  networking.hostName = "chasmfiend";

  # Bitwarden secrets management
  profiles.secrets.enable = true;

  profiles.k3s-node = {
    enable = true;
    role = "init";
    # Token provided by profiles.secrets

    # Additional TLS SANs for cluster access
    tlsSans = [
      "k3s.home.nonbinary.computer"
      "chasmfiend.local"
    ];
  };

  # VM image generation for Proxmox (on archive - smaller node)
  profiles.proxmox-vm = {
    cores = 2;
    memory = 2048;
    proxmox = {
      additionalSpace = "10G";
      cloudInitStorage = "local-zfs";
      diskStorage = "local-zfs";
    };
  };
}

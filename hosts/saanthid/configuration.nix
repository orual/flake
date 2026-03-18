{...}: {
  system.stateVersion = "24.11";

  networking.hostName = "saanthid";

  # 1Password secrets management
  profiles.secrets.enable = true;

  profiles.k3s-node = {
    enable = true;
    role = "server";
    serverAddr = "https://chasmfiend.local:6443";
    # Token automatically provided by opnix via profiles.secrets

    # Additional TLS SANs for cluster access
    tlsSans = [
      "k3s.home.nonbinary.computer"
      "saanthid.local"
    ];
  };

  # VM image generation for Proxmox (on booskie-laptop)
  profiles.proxmox-vm = {
    cores = 2;
    memory = 4096;
    proxmox = {
      additionalSpace = "15G";
      cloudInitStorage = "local-zfs";
      diskStorage = "local-zfs";
    };
  };
}

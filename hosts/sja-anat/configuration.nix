{...}: {
  system.stateVersion = "24.11";

  networking.hostName = "sja-anat";

  # 1Password secrets management
  profiles.secrets.enable = true;

  # Proxmox VM image generation
  profiles.proxmox-vm = {
    enable = true;
    cores = 2;
    memory = 2048;
    proxmox = {
      additionalSpace = "10G";
      cloudInitStorage = "local-zfs";
      diskStorage = "local-zfs";
    };
  };

  # Tranquil PDS
  profiles.tranquil-pds = {
    enable = true;
    domain = "atproto.systems";
    email.fromAddress = "noreply@atproto.systems";
  };
}

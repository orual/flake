{ ... }:

{

  boot.supportedFilesystems = [ "zfs" "xfs" "ext4" "btrfs" ];

  fileSystems."/" = {
    device = "ssd-pool/system/root";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-id/nvme-CT2000P3PSSD8_2504E9A23FD6_1-part2";
    fsType = "vfat";
  };

  fileSystems."/nix" = {
    device = "ssd-pool/local/nix";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  fileSystems."/home/orual" = {
    device = "ssd-pool/home/orual";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  fileSystems."/root" = {
    device = "ssd-pool/home/root";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  # zvols formatted with other filesystems to run software that doesn't like
  # zfs:
  #
  # 1. xfs zvol for docker, because k3d volume mounts don't behave nicely on a
  #    zfs volume
  fileSystems."/var/lib/docker" = {
    device = "/dev/zvol/ssd-pool/system/docker";
    fsType = "xfs";
  };
  # 2. ext4 zvol for atuin; see: https://github.com/atuinsh/atuin/issues/952
  fileSystems."/home/orual/.local/share/atuin" =
    {
      device = "/dev/zvol/ssd-pool/home/atuin";
      fsType = "ext4";
    };

  swapDevices = [
    {
      device = "/dev/disk/by-id/nvme-CT2000P3PSSD8_2504E9A23FD6_1-part1";
      randomEncryption.enable = true;
    }
  ];
}

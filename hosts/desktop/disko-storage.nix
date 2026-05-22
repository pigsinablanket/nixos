{ ... }:
{
  disko.devices = {
    disk = {
      sdb = {
        type = "disk";
        device = "/dev/disk/by-id/scsi-35000c50062424fa7";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };

      sde = {
        type = "disk";
        device = "/dev/disk/by-id/scsi-35000c50062420bcb";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };

      sdc = {
        type = "disk";
        device = "/dev/disk/by-id/scsi-35000c500587c9fb7";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };
    };

    zpool = {
      tank = {
        type = "zpool";
        mode = "raidz";
        options = {
          ashift = "12";
        };
        rootFsOptions = {
          compression = "zstd";
          atime = "off";
          xattr = "sa";
          acltype = "posixacl";
          dnodesize = "auto";
          normalization = "formD";
          mountpoint = "none";
          canmount = "on";
        };
        datasets = {
          # tank = {
          #   type = "zfs_fs";
          #   options.mountpoint = "none";
          # };
          storage = {
            type = "zfs_fs";
            mountpoint = "/storage";
          };
        };
      };
    };
  };
}

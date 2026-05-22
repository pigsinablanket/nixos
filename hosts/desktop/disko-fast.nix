{
  disko.devices = {
    disk.fast = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-SAMSUNG_MZVL21T0HCLR-00BL7_S64PNX0T827847";
      content = {
        type = "gpt";
        partitions = {
          media = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/fast";
              mountOptions = [
                "defaults"
                "noatime"
              ];
            };
          };
        };
      };
    };
  };
}

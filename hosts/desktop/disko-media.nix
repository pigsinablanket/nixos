{
  disko.devices = {
    disk.media = {
      type = "disk";
      device = "/dev/disk/by-id/ata-WDC_WD140EDGZ-11B1PA0_9MH1U5LJ";
      content = {
        type = "gpt";
        partitions = {
          media = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/media";
              mountOptions = [
                "defaults"
                "noatime"
                "largeio"
                "swalloc"
              ];
            };
          };
        };
      };
    };
  };
}

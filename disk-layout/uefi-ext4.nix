{ ... }:

{
  disko.devices.disk.main = {
    type = "disk";

    # disko-install can override this with:
    # --disk main /dev/nvme0n1
    device = "/dev/disk/by-id/OVERRIDDEN-BY-DISKO-INSTALL";

    content = {
      type = "gpt";

      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";

          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";

            mountOptions = [
              "umask=0077"
            ];
          };
        };

        root = {
          size = "100%";

          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}

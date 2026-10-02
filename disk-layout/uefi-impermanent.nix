{ ... }:

{
  disko.devices = {
    disk.main = {
      type = "disk";

      # Overridden during installation with:
      #   --disk main /dev/...
      device = "/dev/disk/by-id/REPLACE-ME";

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

          system = {
            size = "100%";

            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];

              subvolumes = {
                "/nix" = {
                  mountpoint = "/nix";

                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };

                "/home" = {
                  mountpoint = "/home";

                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };

                "/persist" = {
                  mountpoint = "/persist";

                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
              };
            };
          };
        };
      };
    };

    nodev."/" = {
      fsType = "tmpfs";

      mountOptions = [
        "defaults"
        "size=25%"
        "mode=755"
      ];
    };
  };
}

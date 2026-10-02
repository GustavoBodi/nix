{ config, lib, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;

    powerManagement.enable = false;
    powerManagement.finegrained = false;

    open = false;
    nvidiaSettings = true;

    package =
      config.boot.kernelPackages.nvidiaPackages.stable;
  };

  home-manager.users.gustavo.imports = [
    ../../home/desktop.nix
  ];

  fileSystems."/" = {
    device = lib.mkForce "none";
    fsType = lib.mkForce "tmpfs";

    options = lib.mkForce [
      "defaults"
      "size=25%"
      "mode=755"
    ];
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/ae91ae9d-dfc9-43d4-83e5-81a8e711f307";
    fsType = "ext4";
    neededForBoot = true;
  };

  fileSystems."/nix" = {
    device = "/persist/nix";
    fsType = "none";
    options = [ "bind" ];
    neededForBoot = true;
    depends = [ "/persist" ];
  };

  fileSystems."/home" = {
    device = "/persist/home";
    fsType = "none";
    options = [ "bind" ];
    neededForBoot = true;
    depends = [ "/persist" ];
  };
}

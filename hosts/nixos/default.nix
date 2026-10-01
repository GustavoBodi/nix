{ config, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "nixos";

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
}

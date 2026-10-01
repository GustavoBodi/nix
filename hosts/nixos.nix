{ config, ... }:

{
  imports = [
    ../hardware-configuration.nix
  ];

  networking.hostName = "nixos";

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Use the proprietary driver
    modesetting.enable = true;

    # Power management (safe defaults)
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    # Use open kernel module? (ONLY for Turing+ GPUs)
    open = false;

    # Enable nvidia-settings GUI
    nvidiaSettings = true;

    # Driver package (recommended)
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
}

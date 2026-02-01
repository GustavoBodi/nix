# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  nixpkgs.config.allowUnfree = true;

  boot.blacklistedKernelModules = [ "pcspkr" ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.gustavo = import ./home/gustavo.nix;
  users.users.gustavo.shell = pkgs.zsh;

  virtualisation.docker.enable = true;
  virtualisation.docker.daemon.settings = {
    dns = [ "1.1.1.1" "8.8.8.8" ];
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Americas/Sao_Paulo";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };


  fonts = {
    enableDefaultPackages = true;

    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      font-awesome
      material-design-icons
      noto-fonts
      noto-fonts-color-emoji
    ];

    fontconfig = {
      enable = true;

      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" ];
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam, Wine, etc.
  };

  #### NVIDIA driver
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

  services.xserver.screenSection = ''
    Option "metamodes" "DP-0: 1920x1080_120 +0+0 { ForceFullCompositionPipeline=On }, HDMI-0: 1920x1080_75 +1920+0 { ForceFullCompositionPipeline=On }"
  '';

  users.users.gustavo = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "docker" ];
    initialPassword = "";
    packages = with pkgs; [
      tree
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.dbus.enable = true;
  services.xserver.enable = true;
  services.libinput.enable = true;
  services.xserver.displayManager.startx.enable = true;
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.variant = "intl";
  services.xserver.displayManager.lightdm = {
    enable = true;
  
    greeters.gtk = {
      enable = true;
  
      extraConfig = ''
        background=/etc/nixos/home/wallpapers/course_of_the_empire.jpg
      '';
    };
  };

  services.displayManager.gdm.enable = false;


  services.xserver.windowManager.dwm = {
    enable = true;
    package = pkgs.dwm.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        cp ${./dwm/config.h} config.h
      '';
    });
  };

  # Sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  services.pulseaudio.enable = false;

  environment.systemPackages = with pkgs; [
    pavucontrol
    helvum
    vim
    neovim
    dmenu
    xorg.xinit
    xorg.xsetroot
    feh
    git
    firefox
    kitty
    wget
    direnv
  ];

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  programs.zsh.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;
  security.apparmor.enable = true;
  security.sudo.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  security.lockKernelModules = false;
  security.protectKernelImage = true;

  environment.variables.EDITOR = "nvim";
  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?

}


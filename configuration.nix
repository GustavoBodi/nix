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
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.sandbox = true;
  nix.settings.allowed-users = [ "@wheel" ];
  nix.settings.trusted-users = [ "root" ];
  nix.settings.auto-optimise-store = true;

  boot.blacklistedKernelModules = [ "pcspkr" ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.gustavo = import ./home/gustavo.nix;

  users.users.gustavo.shell = pkgs.zsh;
  users.mutableUsers = false;

  virtualisation.docker.enable = true;
  virtualisation.docker.rootless.enable = true;
  virtualisation.docker.rootless.setSocketVariable = true;
  virtualisation.docker.daemon.settings = {
    dns = [ "1.1.1.1" "8.8.8.8" ];
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  networking.nftables.enable = true;

  time.timeZone = "America/Sao_Paulo";

  i18n.defaultLocale = "en_US.UTF-8";

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
  # services.xserver.videoDrivers = [ "nvidia" ];

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

  users.users.gustavo = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" ];
      hashedPasswordFile = "/etc/nixos/secrets/gustavo-password.hash";
      packages = with pkgs; [
      tree
    ];
  };

  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
  };

  security.sudo.wheelNeedsPassword = true;

  services.dbus.enable = true;
  services.libinput.enable = true;

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
    bemenu
    wl-clipboard
    mako
    grim
    slurp
    pavucontrol
    helvum
    vim
    neovim
    git
    firefox
    kitty
    wget
    direnv
  ];

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  programs.zsh.enable = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  programs.river-classic = {
    enable = true;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = false;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;
  security.apparmor = {
    enable = true;
    packages = with pkgs; [
      apparmor-profiles
    ];
    killUnconfinedConfinables = true;
  };
  services.dbus.apparmor = "required";
  security.sudo.enable = true;
  security.audit.enable = true;
  security.auditd.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.PermitRootLogin = "no";
  security.lockKernelModules = true;
  security.protectKernelImage = true;
  security.polkit.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "greeter";
        command = ''
          ${pkgs.tuigreet}/bin/tuigreet \
            --time \
            --remember \
            --asterisks \
            --user-menu \
            --cmd river
        '';
      };
    };
  };
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


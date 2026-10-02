# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.sandbox = true;
  nix.settings.allowed-users = [ "@wheel" ];
  nix.settings.trusted-users = [ "root" ];
  nix.settings.auto-optimise-store = true;

  boot.loader.systemd-boot.editor = false;
  services.fwupd.enable = true;
  boot.blacklistedKernelModules = [ "pcspkr" ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.gustavo.imports = [
    ./home/gustavo.nix
  ];

  users.users.gustavo.shell = pkgs.zsh;
  users.mutableUsers = false;

  virtualisation.docker = {
    enable = false;
  
    rootless = {
      enable = true;
      setSocketVariable = true;
  
      daemon.settings = {
        dns = [ "1.1.1.1" "8.8.8.8" ];
      };
    };
  
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernel.sysctl = {
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
    "fs.protected_hardlinks" = 1;
    "fs.protected_symlinks" = 1;
    "kernel.unprivileged_bpf_disabled" = 1;
    "kernel.perf_event_paranoid" = 3;
    "kernel.yama.ptrace_scope" = 2;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.core.bpf_jit_enable" = 0;
    "kernel.ftrace_enabled" = 0;
    "vm.unprivileged_userfaultfd" = 0;
  };
  
  systemd.coredump.enable = false;
  programs.firejail.enable = true;
  
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
    execWheelOnly = true;
  
    extraConfig = ''
      Defaults timestamp_timeout=5
      Defaults passwd_timeout=1
      Defaults env_reset
      Defaults use_pty
      Defaults logfile=/var/log/sudo.log
    '';
  };

  networking.networkmanager.enable = true;
  networking.firewall.allowPing = false;
  networking.nftables.enable = true;
  programs.nm-applet.enable = true;

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

  users.users.gustavo = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" ];
    hashedPasswordFile = lib.mkDefault "/etc/nixos/secrets/gustavo-password.hash";
    packages = with pkgs; [
      tree
    ];
  };

  system.autoUpgrade = {
    enable = false;
    allowReboot = false;
  };

  services.dbus.enable = true;
  services.dbus.apparmor = "enabled";
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
    crosspipe
    vim
    neovim
    git
    kitty
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
    xwayland.enable = false;
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
  security.forcePageTableIsolation = true;
  boot.kernel.sysctl."kernel.io_uring_disabled" = 2;
  boot.kernelParams = [
    "slab_nomerge"

    "page_alloc.shuffle=1"

    "init_on_free=1"

    "debugfs=off"
  ];

  security.apparmor.enable = true;
  security.apparmor.killUnconfinedConfinables = true;
  security.audit.enable = true;
  security.auditd.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.PermitRootLogin = "no";
  security.lockKernelModules = true;
  security.protectKernelImage = true;
  security.polkit.enable = true;
  boot.kernelModules = [
    "iwlwifi"
    "iwlmvm"

    "ccm"
    "ctr"
    "cmac"
    "gcm"

    "af_packet"
    "usb_storage"
    "uas"

    "usbhid"
    "hid_generic"
  ];

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


{ config, pkgs, lib, ... }:

{
  programs.kitty.enable = true;

  home.packages = with pkgs; [
    feh
    kitty
    jetbrains.clion
    jetbrains.pycharm
    jetbrains.rider
    jetbrains.webstorm
    dotnet-sdk_8
    cmake
    gdb
    xorg.xrandr
    rtorrent
    zathura
    zsh-powerlevel10k
    calibre
    xsecurelock

    # Neovim
    llvmPackages.clang
    llvmPackages.clang-tools
    csharp-ls
    pyright
    black
    nodePackages.typescript
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted
    nodePackages.prettier
    bash-language-server
    shfmt
    nil
  ];

  programs.ssh = {
    enable = true;
  };

  services.ssh-agent = {
    enable = true;
  };

  xsession.enable = true;
  xsession.initExtra = lib.mkAfter ''
    # Monitor layout
    xrandr \
      --output DP-0 --mode 1920x1080 --rate 120 --pos 0x0 --rotate normal \
      --output HDMI-0 --mode 1920x1080 --rate 75 --pos 1920x0 --rotate left

    # Wallpaper
    feh --bg-fill ${./wallpapers/course_of_the_empire.jpg}
  '';

  services.picom = {
    enable = true;

    backend = "glx";
    vSync = true;

    settings = {
      corner-radius = 6;

      inactive-opacity = 0.95;
      active-opacity = 1.0;

      frame-opacity = 1.0;
      shadow = true;
    };

  };

  xdg.configFile = {
    "kitty/kitty.conf".source = ./kitty/kitty.conf;
    "kitty/current-theme.conf".source = ./kitty/current-theme.conf;
  };

  xdg.configFile."zsh/p10k.zsh".source = ./zsh/p10k.zsh;

  home.file.".rtorrent.rc".source =
    ./rtorrent/rtorrent.rc;

  home.activation.createTorrentDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/torrents"
  '';

  xdg.configFile."zathura/zathurarc".source =
    ./zathura/zathurarc;

  programs.zsh = {
    enable = true;

    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      share = true;
    };

    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
      rebuild = "sudo nixos-rebuild switch";
    };

    initExtraFirst = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    '';

    initExtra = lib.mkAfter ''
      source ~/.config/zsh/p10k.zsh

      bindkey -e
    '';

  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.neovim.plugins = with pkgs.vimPlugins; [
    nvim-lspconfig
    nvim-treesitter.withAllGrammars
    nvim-cmp
    cmp-nvim-lsp

    telescope-nvim
    plenary-nvim
    telescope-file-browser-nvim
    toggleterm-nvim
    bufferline-nvim
  ];

  xdg.configFile."nvim".source = ./nvim;

  home.stateVersion = "25.11";
}

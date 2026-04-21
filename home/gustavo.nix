{ config, pkgs, lib, ... }:

{
  programs.kitty.enable = true;

  home.packages = with pkgs; [
    grim
    slurp
    satty

    (writeShellScriptBin "flameshot" ''
      mkdir -p "$HOME/Pictures/Screenshots"
      file="$HOME/Pictures/Screenshots/$(date +%F-%H%M%S).png"
      grim -g "$(slurp)" "$file" && satty --filename "$file" --fullscreen
    '')

    wlr-randr
    unar
    swaybg
    swaylock
    wl-clipboard
    playerctl
    python3
    kitty
    jetbrains.webstorm
    jetbrains.rust-rover
    dotnet-sdk_10
    dotnetCorePackages.sdk_10_0
    cmake
    gdb
    rtorrent
    zathura
    zsh-powerlevel10k
    calibre
    killall
    nodejs
    vscode
    unzip
    zip
    steam-run
    docker
    libreoffice
    openvpn
    openssl
    neofetch
    github-cli
    azure-cli
    bicep
    terraform
    gnumake
    jq

    (symlinkJoin {
      name = "rider-steam";
      paths = [ jetbrains.rider ];
      buildInputs = [ makeWrapper ];
      postBuild = ''
        mv $out/bin/rider $out/bin/.rider-unwrapped
    
        cat > $out/bin/rider <<EOF
        #!/usr/bin/env bash
        exec ${steam-run}/bin/steam-run \
          $out/bin/.rider-unwrapped "\$@"
        EOF
    
        chmod +x $out/bin/rider
      '';
    })


    (symlinkJoin {
      name = "clion-steam";
      paths = [ jetbrains.clion ];
      buildInputs = [ makeWrapper ];
      postBuild = ''
        mv $out/bin/clion $out/bin/.clion-unwrapped
    
        cat > $out/bin/clion <<EOF
        #!/usr/bin/env bash
        exec ${steam-run}/bin/steam-run \
          $out/bin/.clion-unwrapped "\$@"
        EOF
    
        chmod +x $out/bin/clion
      '';
    })

    discord
    spotify

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
  
    enableDefaultConfig = false;
  
    matchBlocks."*" = {
      forwardAgent = false;
      compression = true;
      serverAliveInterval = 60;
      serverAliveCountMax = 3;
      hashKnownHosts = true;
    };
  };

  services.ssh-agent = {
    enable = true;
  };

  wayland.windowManager.river = {
    enable = true;
    package = null;
    xwayland.enable = false;
    systemd.enable = true;
  
  extraConfig = ''
    riverctl keyboard-layout -variant intl us

    sh -c 'sleep 1; wlr-randr \
      --output DP-1 --mode 1920x1080@144.001007Hz \
      --output HDMI-A-1 --transform 90 --right-of DP-1' &

    riverctl set-repeat 50 300
    riverctl background-color 0x282828
    riverctl border-width 1
    riverctl border-color-focused 0xcc241d
    riverctl border-color-unfocused 0x504945

    riverctl default-layout rivertile
    rivertile -view-padding 1 -outer-padding 1 &

    swaybg -i ${./wallpapers/course_of_the_empire.jpg} -m fill &
    mako &

    # Applications
    riverctl map normal Super Return spawn "kitty"
    riverctl map normal Super D spawn "bemenu-run"
    riverctl map normal Super B spawn "firefox"
    riverctl map normal Super F12 spawn "swaylock -f"

    # Media
    riverctl map normal None XF86AudioPlay spawn "playerctl play-pause"
    riverctl map normal None XF86AudioNext spawn "playerctl next"
    riverctl map normal None XF86AudioPrev spawn "playerctl previous"

    # Focus / stack
    riverctl map normal Super J focus-view next
    riverctl map normal Super K focus-view previous
    riverctl map normal Super E zoom

    # DWM-like main area controls via rivertile
    riverctl map normal Super H send-layout-cmd rivertile "main-ratio -0.05"
    riverctl map normal Super L send-layout-cmd rivertile "main-ratio +0.05"
    riverctl map normal Super I send-layout-cmd rivertile "main-count +1"
    riverctl map normal Super P send-layout-cmd rivertile "main-count -1"

    # Floating / fullscreen
    riverctl map normal Super Shift Space toggle-float
    riverctl map normal Super M toggle-fullscreen

    # Close / exit
    riverctl map normal Super Q close
    riverctl map normal Super+Shift Q exit

    # Output focus / send view to output
    riverctl map normal Super Comma focus-output previous
    riverctl map normal Super Period focus-output next
    riverctl map normal Super+Shift Comma send-to-output -current-tags previous
    riverctl map normal Super+Shift Period send-to-output -current-tags next
    riverctl focus-output DP-1
    riverctl send-layout-cmd rivertile "main-location left"

        # Tags 1..9, matching DWM-style behavior
    for i in 1 2 3 4 5 6 7 8 9; do
      tag=$((1 << ($i - 1)))

      riverctl map normal Super $i set-focused-tags $tag
      riverctl map normal Super+Control $i toggle-focused-tags $tag
      riverctl map normal Super+Shift $i set-view-tags $tag
      riverctl map normal Super+Control+Shift $i toggle-view-tags $tag
    done
  '';
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

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      '')
    
      (lib.mkAfter ''
        source ~/.config/zsh/p10k.zsh
        bindkey -e
      '')
    ];
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

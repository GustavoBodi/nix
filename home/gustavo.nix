{ config, pkgs, lib, ... }:

{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 24;

        modules-left = [ "river/tags" ];
        modules-center = [ "river/window" ];
        modules-right = [ "clock" ];

        "river/tags" = {
          num-tags = 9;
          tag-labels = [ "1" "2" "3" "4" "5" "6" "7" "8" "9" ];
        };

        "river/window" = {
          max-length = 80;
        };

        clock = {
          format = "{:%Y-%m-%d %H:%M}";
        };
      };
    };

    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: monospace;
        font-size: 12px;
        min-height: 0;
      }

      window#waybar {
        background: #111111;
        color: #dddddd;
      }

      #tags button {
        padding: 0 8px;
        background: transparent;
        color: #888888;
      }

      #tags button.focused {
        background: #333333;
        color: #ffffff;
      }

      #tags button.occupied {
        color: #dddddd;
      }

      #window, #clock {
        padding: 0 8px;
      }
    '';
  };

  home.packages = with pkgs; [
    prism-model-checker
    isabelle
    grim
    slurp
    satty

    (writeShellScriptBin "flameshot" ''
      set -euo pipefail
    
      mkdir -p "$HOME/screenshots"
      file="$HOME/screenshots/$(date +%F-%H%M%S).png"
    
      grim -g "$(slurp)" "$file"
    
      satty \
        --filename "$file" \
        --fullscreen \
        --copy-command "${pkgs.wl-clipboard}/bin/wl-copy --type image/png"
    '')
    file
    poppler-utils
    mpv
    blender
    wlr-randr
    unar
    swayimg
    swaybg
    swaylock
    wl-clipboard
    playerctl
    python3
    kitty
    jetbrains.webstorm
    dotnet-sdk_10
    dotnetCorePackages.sdk_10_0
    cmake
    gdb
    rtorrent
    zathura
    zsh-powerlevel10k
    calibre
    killall
    uv
    # nodejs
    vscode
    unzip
    zip
    # steam-run
    libreoffice
    openvpn
    openssl
    fastfetch
    # github-cli
    # azure-cli
    gnumake
    jq
    yubikey-manager

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


    # (symlinkJoin {
    #   name = "clion-steam";
    #   paths = [ jetbrains.clion ];
    #   buildInputs = [ makeWrapper ];
    #   postBuild = ''
    #     mv $out/bin/clion $out/bin/.clion-unwrapped
    # 
    #     cat > $out/bin/clion <<EOF
    #     #!/usr/bin/env bash
    #     exec ${steam-run}/bin/steam-run \
    #       $out/bin/.clion-unwrapped "\$@"
    #     EOF
    # 
    #     chmod +x $out/bin/clion
    #   '';
    # })

    discord

    (writeShellScriptBin "spotify" ''
      exec ${pkgs.spotify}/bin/spotify \
        --enable-features=UseOzonePlatform \
        --ozone-platform=wayland \
        "$@"
    '')

    # Neovim
    llvmPackages.clang
    llvmPackages.clang-tools
    csharp-ls
    pyright
    black
    typescript
    typescript-language-server
    vscode-langservers-extracted
    prettier
    bash-language-server
    shfmt
    nil
  ];

  programs.tmux = {
    enable = true;
    shortcut = "t";
    extraConfig = ''
	bind h split-window -h
	bind v split-window -v
	bind -n M-Left select-pane -L
	bind -n M-Right select-pane -R
	bind -n M-Up select-pane -U
	bind -n M-Down select-pane -D
	unbind '"'
	unbind %
    '';
    keyMode = "vi";
  };

  programs.ssh = {
    enable = true;
  
    enableDefaultConfig = false;
  
    settings."*" = {
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

  services.kanshi = {
    enable = true;
    settings = [
      {
        profile.name = "dual";
        profile.outputs = [
          {
            criteria = "DP-1";
            mode = "1920x1080@144.001007Hz";
            position = "0,0";
            status = "enable";
          }
          {
            criteria = "HDMI-A-1";
            transform = "90";
            position = "1920,0";
            status = "enable";
          }
        ];
      }
    ];
  };

  wayland.windowManager.river = {
    enable = true;
    package = null;
    xwayland.enable = true;
    systemd.enable = true;
  
  extraConfig = ''
    riverctl keyboard-layout -variant intl us

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
    riverctl map normal Super F12 spawn "swaylock -f -i ${./wallpapers/consummation_of_the_empire.jpg} -s fill"


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
  
    # 26.05 changed these defaults.
    # Your listed plugins don't require either provider.
    withRuby = false;
    withPython3 = false;
  
    plugins = with pkgs.vimPlugins; [
      nvim-lspconfig
  
      # Compatibility with your pre-26.05 Treesitter config.
      nvim-treesitter.withAllGrammars
  
      nvim-cmp
      cmp-nvim-lsp
  
      telescope-nvim
      plenary-nvim
      telescope-file-browser-nvim
      toggleterm-nvim
      bufferline-nvim
    ];
  };

  xdg.configFile."nvim".source = ./nvim;

  home.stateVersion = "25.11";
}

{ ... }:

{
  fileSystems."/persist".neededForBoot = true;
  fileSystems."/nix".neededForBoot = true;

  fileSystems."/home" = {
    device = "none";
    fsType = "tmpfs";
  
    options = [
      "defaults"
      "mode=755"
    ];
  
    neededForBoot = true;
  };

  environment.persistence."/persist" = {
    hideMounts = true;

    directories = [
      "/etc/nixos"
      "/var/lib/nixos"
      "/etc/NetworkManager/system-connections"
    ];

    files = [
      "/etc/machine-id"
    ];

    users.gustavo = {
      directories = [
        "documents"
        "downloads"
        "music"
        "screenshots"
        "src"
        "torrents"
        "videos"
        "vpn"

        ".config/mozilla/firefox"

        ".config/spotify"

        ".config/discord"

        ".config/Code"
        ".vscode"

        {
          directory = ".ssh";
          mode = "0700";
        }
      ];

      files = [
        ".zsh_history"
	".gitconfig"
      ];
    };
  };

  users.users.gustavo.hashedPasswordFile =
    "/persist/etc/nixos/secrets/gustavo-password.hash";
}

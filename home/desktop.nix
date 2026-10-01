{ lib, ... }:

{
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

  wayland.windowManager.river.extraConfig = lib.mkAfter ''
    riverctl focus-output DP-1
  '';
}

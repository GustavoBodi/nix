{
  description = "Gustavo's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    { nixpkgs, home-manager, disko, ... }:

    let
      system = "x86_64-linux";

      mkHost = host:
        nixpkgs.lib.nixosSystem {
          inherit system;

          modules = [
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            ./configuration.nix

            {
              networking.hostName = host;
            }

            ./hosts/${host}
          ];
      };

      hosts = {
        nixos = mkHost "nixos";
      };

    in
    {
      nixosConfigurations = hosts;

      checks.${system} =
        nixpkgs.lib.mapAttrs
          (_name: host: host.config.system.build.toplevel)
          hosts;
    };
}

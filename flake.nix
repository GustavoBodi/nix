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

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "";
      inputs.home-manager.follows = "";
    };

  };

  outputs =
    { nixpkgs, home-manager, disko, impermanence, ... }:

    let
      system = "x86_64-linux";

      
      legacyDiskLayoutHosts = [
        "nixos"
      ];


      mkHost = host:
        let
          legacyDisk =
            nixpkgs.lib.elem host legacyDiskLayoutHosts;
        in
        nixpkgs.lib.nixosSystem {
          inherit system;

          modules =
            [
              disko.nixosModules.disko
              impermanence.nixosModules.impermanence
              home-manager.nixosModules.home-manager

              ./configuration.nix
              ./modules/impermanence.nix

              {
                networking.hostName = host;
              }

              ./hosts/${host}/hardware-configuration.nix
            ]

            # Fresh/reinstalled machines use the proper
            # impermanent Disko layout.
            ++ nixpkgs.lib.optional
              (!legacyDisk)
              ./disk-layout/uefi-impermanent.nix

            # Host-specific hardware/configuration.
            ++ nixpkgs.lib.optional
              (builtins.pathExists ./hosts/${host}/extra.nix)
              ./hosts/${host}/extra.nix;
        };
      hostNames =
        builtins.attrNames (
          nixpkgs.lib.filterAttrs
            (_name: type: type == "directory")
            (builtins.readDir ./hosts)
        );
      
      hosts = nixpkgs.lib.genAttrs hostNames mkHost;

      in
      {
        nixosConfigurations = hosts;
      
        checks.${system} =
          nixpkgs.lib.mapAttrs
            (_name: host: host.config.system.build.toplevel)
            hosts;
      
        packages.${system}.disko-install =
          disko.packages.${system}.disko-install;
      };
}

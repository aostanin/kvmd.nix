{
  description = "NixOS packaging and modules for kvmd";

  nixConfig = {
    extra-substituters = ["https://aostanin.cachix.org"];
    extra-trusted-public-keys = ["aostanin.cachix.org-1:loDfTVc4XTxROFAPv3NKNfKzLCKEzAGj8aPKJFbRs5Q="];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} ({
      self,
      lib,
      ...
    }: let
      variants = ["v2-hdmi-rpi4" "v2-hdmiusb-rpi4"];

      mkVariantModule = variant: {
        imports = [
          inputs.nixos-hardware.nixosModules.raspberry-pi-4
          ./modules/variants/${variant}.nix
        ];
        _module.args.kvmdNixosHardware = inputs.nixos-hardware;
      };

      mkVariantConfiguration = variant:
        inputs.nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            self.nixosModules.kvmd
            self.nixosModules.${variant}
            ./configurations/common.nix
          ];
        };
    in {
      imports = [inputs.treefmt-nix.flakeModule];
      systems = ["x86_64-linux" "aarch64-linux"];
      perSystem = {pkgs, ...}: {
        treefmt.programs = {
          alejandra.enable = true;
          prettier = {
            enable = true;
            settings = {
              proseWrap = "always";
              printWidth = 80;
            };
          };
          deadnix = {
            enable = true;
            no-lambda-pattern-names = true;
          };
          statix = {
            enable = true;
            disabled-lints = ["repeated_keys"];
          };
        };
        packages = rec {
          default = kvmd;
          janus-assets = pkgs.callPackage ./packages/janus-assets.nix {inherit pikvm-packages;};
          kvmd = pkgs.callPackage ./packages/kvmd.nix {inherit pikvm-packages;};
          pikvm-packages = pkgs.callPackage ./packages/pikvm-packages.nix {};
        };
      };
      flake.nixosModules =
        {
          default = self.nixosModules.kvmd;
          kvmd = {
            imports = [./modules/kvmd];
            _module.args.kvmdPackages = self.packages;
          };
        }
        // lib.genAttrs variants mkVariantModule;
      flake.nixosConfigurations = lib.genAttrs variants mkVariantConfiguration;
    });
}

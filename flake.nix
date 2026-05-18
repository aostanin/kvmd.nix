{
  description = "NixOS packaging and modules for kvmd";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pikvm-kvmd = {
      url = "github:pikvm/kvmd";
      flake = false;
    };
    pikvm-packages = {
      url = "github:pikvm/packages";
      flake = false;
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} ({self, ...}: {
      imports = [inputs.treefmt-nix.flakeModule];
      systems = ["x86_64-linux" "aarch64-linux"];
      perSystem = {pkgs, ...}: {
        treefmt.programs = {
          alejandra.enable = true;
          deadnix = {
            enable = true;
            no-lambda-pattern-names = true;
          };
          statix = {
            enable = true;
            disabled-lints = ["repeated_keys"];
          };
        };
        packages.kvmd = pkgs.callPackage ./packages/kvmd.nix {
          inherit (inputs) pikvm-kvmd pikvm-packages;
        };
      };
      flake.nixosModules.kvmd = {
        imports = [./modules/kvmd];
        _module.args.kvmdPackages = self.packages;
      };
      flake.nixosModules.v2-hdmi-rpi4 = {
        imports = [
          inputs.nixos-hardware.nixosModules.raspberry-pi-4
          ./modules/v2-hdmi-rpi4.nix
        ];
        _module.args.inputs = inputs;
      };
    });
}

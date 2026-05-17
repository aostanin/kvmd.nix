{
  description = "NixOS packaging and modules for kvmd";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
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
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux"];
      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;
        packages.kvmd = pkgs.callPackage ./packages/kvmd.nix {
          inherit (inputs) pikvm-kvmd;
        };
      };
    };
}

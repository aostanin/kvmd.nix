{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.kvmd;
  yaml = pkgs.formats.yaml {};

  # kvmd's platform configs pass streamer options unconditionally, but the
  # ustreamer nixpkgs ships may predate them. ustreamer then exits at argv parse
  # and kvmd respawns it about once a second, which looks like dead capture
  # hardware rather than a version mismatch.
  #
  # Each option maps to the first ustreamer release that understands it, so an
  # entry stops applying by itself once nixpkgs catches up. cmd_remove matches
  # whole arguments, so values are spelled as kvmd's configs.default has them.
  introducedIn = {
    "--cpu-scaling-governor-idle=schedutil" = "6.67";
    "--cpu-scaling-governor-active=performance" = "6.67";
  };

  unsupported =
    lib.filter
    (arg: lib.versionOlder cfg.package.ustreamer.version introducedIn.${arg})
    (lib.attrNames introducedIn);
in {
  config = lib.mkIf (cfg.enable && unsupported != []) {
    warnings = [
      ''
        kvmd ${cfg.package.version} expects a newer ustreamer than the ${cfg.package.ustreamer.version}
        nixpkgs provides, so these streamer options are being dropped: ${lib.concatStringsSep " " unsupported}
        Video works without them; they return once nixpkgs ships a newer ustreamer.
      ''
    ];

    environment.etc."kvmd/override.d/06-nixos-ustreamer-compat.yaml".source = yaml.generate "06-nixos-ustreamer-compat.yaml" {
      kvmd.streamer.cmd_remove = unsupported;
    };
  };
}

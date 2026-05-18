{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.kvmd;
  yaml = pkgs.formats.yaml {};
in {
  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = ["d /var/lib/kvmd/msd 0755 kvmd kvmd -"];

    # Call the remount helper directly as the kvmd user; it no longer
    # needs root (the remount itself is a no-op).
    environment.etc."kvmd/override.d/01-nixos-msd.yaml".source = yaml.generate "01-nixos-msd.yaml" {
      kvmd.msd.remount_cmd = [(lib.getExe' cfg.package "kvmd-helper-otgmsd-remount") "{mode}"];
    };
  };
}

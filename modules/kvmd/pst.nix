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
    users.groups.kvmd-pst = {};
    users.users.kvmd-pst = {
      isSystemUser = true;
      group = "kvmd-pst";
      extraGroups = ["kvmd"];
      description = "PiKVM - Persistent storage";
    };

    systemd.tmpfiles.rules = ["d /var/lib/kvmd/pst 0775 kvmd-pst kvmd-pst -"];

    # Call the remount helper directly as the kvmd-pst user; it no longer
    # needs root (the remount itself is a no-op).
    environment.etc."kvmd/override.d/05-nixos-pst.yaml".source = yaml.generate "05-nixos-pst.yaml" {
      pst.remount_cmd = [(lib.getExe' cfg.package "kvmd-helper-pst-remount") "{mode}"];
    };

    systemd.services.kvmd-pst = {
      description = "PiKVM - Persistent storage manager";
      wantedBy = ["multi-user.target"];
      before = ["kvmd.service"];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = 3;
        TimeoutStopSec = 5;
        User = "kvmd-pst";
        Group = "kvmd-pst";
        ExecStart = "${lib.getExe' cfg.package "kvmd-pst"} --run";
      };
    };
  };
}

{
  config,
  lib,
  ...
}: let
  cfg = config.services.kvmd;
in {
  options.services.kvmd.nbd.enable = lib.mkEnableOption "the kvmd-nbd server";

  config = lib.mkIf (cfg.enable && cfg.nbd.enable) {
    users.groups.kvmd-nbd = {};
    users.users = {
      kvmd-nbd = {
        isSystemUser = true;
        group = "kvmd-nbd";
        extraGroups = ["kvmd"];
        description = "PiKVM - NBD server";
      };
      kvmd.extraGroups = ["kvmd-nbd"];
    };

    boot.kernelModules = ["nbd"];

    systemd.services.kvmd-nbd = {
      description = "PiKVM - NBD server";
      wantedBy = ["multi-user.target"];
      after = ["systemd-modules-load.service"];
      before = ["kvmd.service"];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = 3;
        TimeoutStopSec = 5;
        User = "kvmd-nbd";
        Group = "kvmd-nbd";
        # libnfs binds a privileged source port for exports with `secure`
        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
        ExecStart = "${lib.getExe' cfg.package "kvmd-nbd"} --run";
      };
    };
  };
}

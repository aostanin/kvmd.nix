{
  config,
  lib,
  ...
}: let
  cfg = config.services.kvmd;
in {
  options.services.kvmd.watchdog.enable = lib.mkEnableOption "PiKVM's RTC-based hardware watchdog";

  config = lib.mkIf (cfg.enable && cfg.watchdog.enable) {
    systemd.services.kvmd-watchdog = {
      description = "PiKVM - RTC-based hardware watchdog";
      wantedBy = ["multi-user.target"];
      after = ["systemd-modules-load.service"];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = 3;
        ExecStart = "${lib.getExe' cfg.package "kvmd-watchdog"} run";
        TimeoutStopSec = 3;
      };
    };
  };
}

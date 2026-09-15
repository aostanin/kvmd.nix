{
  config,
  lib,
  ...
}: let
  cfg = config.services.kvmd;
  oled = lib.getExe' cfg.package "kvmd-oled";
in {
  options.services.kvmd.oled.enable = lib.mkEnableOption "the PiKVM OLED display";

  config = lib.mkIf (cfg.enable && cfg.oled.enable) {
    hardware.i2c.enable = true;
    services.udev.extraRules = ''
      SUBSYSTEM=="i2c-dev", KERNEL=="i2c-1", TAG+="systemd"
    '';
    users.groups.kvmd-oled = {};
    users.users.kvmd-oled = {
      isSystemUser = true;
      group = "kvmd-oled";
      # Sensors subscribes to the authenticated kvmd WebSocket over its
      # UNIX socket, including health, uptime and connected clients.
      extraGroups = ["kvmd" "kvmd-selfauth" config.hardware.i2c.group];
      description = "PiKVM - OLED display";
    };

    systemd.services.kvmd-oled = {
      description = "PiKVM - A small OLED daemon";
      wantedBy = ["multi-user.target"];
      wants = ["kvmd.service"];
      requires = ["dev-i2c\\x2d1.device"];
      after = ["systemd-modules-load.service" "kvmd.service" "dev-i2c\\x2d1.device"];
      # Run while the display process still owns the device. Separate
      # shutdown units race its stop job under systemd's shutdown ordering.
      preStop = ''
        if [ -n "$MAINPID" ]; then
          case "$(${config.systemd.package}/bin/systemctl list-jobs --no-legend)" in
            *reboot.target*) kill -USR1 "$MAINPID"; sleep 1 ;;
            *shutdown.target*) kill -USR2 "$MAINPID"; sleep 1 ;;
          esac
        fi
      '';
      serviceConfig = {
        User = "kvmd-oled";
        Group = "kvmd-oled";
        Type = "simple";
        Restart = "always";
        RestartSec = 3;
        ExecStartPre = "${oled} --interval=3 --clear-on-exit --image=@hello.ppm";
        ExecStart = oled;
        TimeoutStopSec = 3;
      };
    };
  };
}

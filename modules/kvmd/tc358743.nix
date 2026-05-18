{
  config,
  lib,
  ...
}: let
  cfg = config.services.kvmd;
  isHdmiCsi = lib.hasInfix "-hdmi-" cfg.variant;
  v4l2Ctl = lib.getExe' cfg.package.v4l-utils "v4l2-ctl";
in {
  options.services.kvmd.edidHex = lib.mkOption {
    type = lib.types.path;
    default = "${cfg.configsDir}/kvmd/edid/v2.hex";
    defaultText = lib.literalExpression ''"''${package}/share/kvmd/configs.default/kvmd/edid/v2.hex"'';
    description = "EDID hex loaded into the TC358743 (HDMI-CSI variants).";
  };

  config = lib.mkIf (cfg.enable && isHdmiCsi) {
    systemd.services.kvmd-tc358743 = {
      description = "PiKVM - EDID loader for TC358743";
      wants = ["dev-kvmd\\x2dvideo.device"];
      after = ["dev-kvmd\\x2dvideo.device" "systemd-modules-load.service"];
      before = ["kvmd.service"];
      wantedBy = ["multi-user.target"];
      # Only re-apply when the EDID itself changes (clearing/re-setting
      # blips capture), not on every unrelated nixos-rebuild switch.
      restartTriggers = [cfg.edidHex];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = 5;
        ExecStart = "${v4l2Ctl} --device=/dev/kvmd-video --set-edid=file=${cfg.edidHex} --info-edid";
        ExecStop = "${v4l2Ctl} --device=/dev/kvmd-video --clear-edid";
      };
    };
  };
}

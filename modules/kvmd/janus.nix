{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.kvmd;
  yaml = pkgs.formats.yaml { };
in
{
  options.services.kvmd.janus = {
    enable = lib.mkEnableOption "kvmd-janus (WebRTC / H.264 video)";
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open the WebRTC port range (UDP 20000-40000) in the firewall.";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.janus.enable) {
    users.groups.kvmd-janus = {};
    users.users = {
      kvmd-janus = {
        isSystemUser = true;
        group = "kvmd-janus";
        extraGroups = ["kvmd" "audio"];
        description = "PiKVM - Janus WebRTC";
      };
      nginx.extraGroups = lib.optionals cfg.nginx.enable ["kvmd-janus"];
    };

    # kvmd's janus cmd hardcodes PiKVM paths for the ustreamer plugin and
    # jcfg dir; redirect to the nix store (the janus binary itself is
    # already patched in the package).
    environment.etc."kvmd/override.d/04-nixos-janus.yaml".source = yaml.generate "04-nixos-janus.yaml" {
      janus = {
        cmd_remove = [
          "--plugins-folder=/usr/lib/ustreamer/janus"
          "--configs-folder=/etc/kvmd/janus"
        ];
        cmd_append = [
          "--plugins-folder=${pkgs.ustreamer}/lib/ustreamer/janus"
          "--configs-folder=${cfg.configsDir}/janus"
        ];
      };
    };

    networking.firewall.allowedUDPPortRanges = lib.mkIf cfg.janus.openFirewall [
      # https://github.com/pikvm/kvmd/blob/c1dd48bd99cec08bc986d7cc2af49a50b4b1671b/configs/janus/janus.jcfg#L12
      {
        from = 20000;
        to = 40000;
      }
    ];

    systemd.services.kvmd-janus = {
      description = "PiKVM - Janus WebRTC Gateway";
      wantedBy = ["multi-user.target"];
      after = ["network.target" "network-online.target" "nss-lookup.target" "kvmd.service"];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = 3;
        User = "kvmd-janus";
        Group = "kvmd-janus";
        AmbientCapabilities = "CAP_NET_RAW";
        LimitNOFILE = 65536;
        UMask = "0117";
        ExecStart = "${lib.getExe' cfg.package "kvmd-janus"} --run";
        TimeoutStopSec = 10;
        KillMode = "mixed";
      };
    };
  };
}

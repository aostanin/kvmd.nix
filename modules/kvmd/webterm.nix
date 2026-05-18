{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.kvmd;
  webtermHome = "/var/lib/kvmd-webterm";
  webtermCtx = pkgs.runCommand "kvmd-webterm-ctx.conf" {} ''
    substitute ${cfg.package}/share/kvmd/extras/webterm/nginx.ctx-server.conf $out \
      --replace-quiet /etc/kvmd/nginx ${cfg.configsDir}/nginx
  '';
  loginShell = pkgs.writeShellScript "kvmd-webterm-login" ''
    echo -ne "\033]0;PiKVM Terminal: $(${pkgs.hostname}/bin/hostname -f) (ttyd)\007"
    ${pkgs.coreutils}/bin/cat /etc/motd 2>/dev/null || true
    export TERM=linux
    umask 0022
    exec ${pkgs.bashInteractive}/bin/bash
  '';
in {
  options.services.kvmd.webterm.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''kvmd-webterm: a ttyd web terminal surfaced as the "Terminal" entry in the web UI (stock PiKVM ships it).'';
  };

  config = lib.mkIf (cfg.enable && cfg.webterm.enable) (lib.mkMerge [
    {
      users.groups.kvmd-webterm = {};
      users.users.kvmd-webterm = {
        isSystemUser = true;
        group = "kvmd-webterm";
        extraGroups = ["kvmd"];
        description = "PiKVM - Web terminal";
        home = webtermHome;
        createHome = true;
      };

      systemd.services.kvmd-webterm = {
        description = "PiKVM - Web terminal (ttyd)";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];
        serviceConfig = {
          User = "kvmd-webterm";
          Group = "kvmd-webterm";
          WorkingDirectory = webtermHome;
          Restart = "always";
          RestartSec = 1;
          UMask = "0117";
          ExecStart = "${pkgs.ttyd}/bin/ttyd -W --interface=/run/kvmd/ttyd.sock --port=0 ${loginShell}";
        };
      };
    }
    (lib.mkIf cfg.nginx.enable {
      users.users.nginx.extraGroups = ["kvmd-webterm"];
      services.nginx.upstreams.ttyd.servers."unix:/run/kvmd/ttyd.sock" = {
        fail_timeout = "0s";
        max_fails = 0;
      };
      services.nginx.virtualHosts.${cfg.hostName}.extraConfig =
        lib.mkAfter (builtins.readFile webtermCtx);
    })
  ]);
}

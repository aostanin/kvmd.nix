{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.kvmd;
  sslDir = "/var/lib/kvmd/nginx-ssl";

  ctxServerConf = pkgs.runCommand "kvmd-nginx-ctx-server.conf" {} ''
    substitute ${cfg.configsDir}/nginx/kvmd.ctx-server.conf $out \
      --replace-quiet /usr/share/janus/javascript ${cfg.package.janusAssets} \
      --replace-quiet /etc/kvmd/web.css ${cfg.webCss} \
      --replace-quiet /etc/kvmd/nginx ${cfg.configsDir}/nginx
  '';
in {
  options.services.kvmd.nginx = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Configure nginx as the kvmd HTTP entrypoint.";
    };
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open the HTTP/HTTPS ports (80, 443) in the firewall.";
    };
    https = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Serve over HTTPS (self-signed if no cert supplied).";
    };
    sslCertificate = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "TLS certificate; null generates a self-signed one.";
    };
    sslCertificateKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "TLS key; null generates a self-signed one.";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.nginx.enable) {
    # nginx reaches kvmd's group-owned sockets in /run/kvmd; other
    # daemons append their own groups here (list option merges).
    users.users.nginx.extraGroups = ["kvmd" "kvmd-media"];

    networking.firewall.allowedTCPPorts =
      lib.mkIf cfg.nginx.openFirewall ([80] ++ lib.optional cfg.nginx.https 443);

    services.nginx = {
      enable = true;
      upstreams = {
        kvmd.servers."unix:/run/kvmd/kvmd.sock" = {
          fail_timeout = "0s";
          max_fails = 0;
        };
        ustreamer.servers."unix:/run/kvmd/ustreamer.sock" = {
          fail_timeout = "0s";
          max_fails = 0;
        };
        media.servers."unix:/run/kvmd/media.sock" = {
          fail_timeout = "0s";
          max_fails = 0;
        };
        janus-ws.servers."unix:/run/kvmd/janus-ws.sock" = {
          fail_timeout = "0s";
          max_fails = 0;
        };
      };
      virtualHosts.${cfg.hostName} = {
        default = true;
        forceSSL = cfg.nginx.https;
        sslCertificate = lib.mkIf cfg.nginx.https (
          if cfg.nginx.sslCertificate != null
          then cfg.nginx.sslCertificate
          else "${sslDir}/server.crt"
        );
        sslCertificateKey = lib.mkIf cfg.nginx.https (
          if cfg.nginx.sslCertificateKey != null
          then cfg.nginx.sslCertificateKey
          else "${sslDir}/server.key"
        );
        extraConfig = builtins.readFile ctxServerConf;
      };
    };

    # nginx must reach kvmd sockets under /run/kvmd; the upstream unit's
    # ProtectHome would block traversal of those service runtime dirs.
    systemd.services.nginx.serviceConfig.ProtectHome = false;

    systemd.services.kvmd-nginx-certgen = lib.mkIf (cfg.nginx.https && cfg.nginx.sslCertificate == null) {
      description = "PiKVM - Generate self-signed nginx certificate";
      wantedBy = ["nginx.service"];
      before = ["nginx.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        if [ ! -e ${sslDir}/server.crt ]; then
          mkdir -p ${sslDir}
          ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:2048 -nodes \
            -keyout ${sslDir}/server.key -out ${sslDir}/server.crt \
            -days 3650 -subj "/CN=${cfg.hostName}"
          chmod 640 ${sslDir}/server.key
          chgrp nginx ${sslDir}/server.key ${sslDir}/server.crt || true
        fi
      '';
    };
  };
}

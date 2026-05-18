{
  config,
  lib,
  pkgs,
  kvmdPackages,
  ...
}: let
  cfg = config.services.kvmd;
  inherit (cfg) configsDir;
  variants = [
    "v0-hdmi-rpi2"
    "v0-hdmi-rpi3"
    "v0-hdmi-zero2w"
    "v0-hdmiusb-rpi2"
    "v0-hdmiusb-rpi3"
    "v0-hdmiusb-zero2w"
    "v1-hdmi-rpi2"
    "v1-hdmi-rpi3"
    "v1-hdmi-zero2w"
    "v1-hdmiusb-rpi2"
    "v1-hdmiusb-rpi3"
    "v1-hdmiusb-zero2w"
    "v2-hdmi-rpi3"
    "v2-hdmi-rpi4"
    "v2-hdmi-zero2w"
    "v2-hdmiusb-rpi4"
    "v3-hdmi-rpi4"
    "v4mini-hdmi-rpi4"
    "v4plus-hdmi-rpi4"
  ];
  yaml = pkgs.formats.yaml {};
  mainYaml = "${configsDir}/kvmd/main/${cfg.variant}.yaml";
  overrideYaml = yaml.generate "kvmd-override.yaml" cfg.overrideConfig;
  metaYaml = yaml.generate "kvmd-meta.yaml" cfg.metaConfig;
  testedVariants = ["v2-hdmi-rpi4"];
in {
  imports = [
    ./ipmi.nix
    ./janus.nix
    ./kvmd.nix
    ./media.nix
    ./msd.nix
    ./nbd.nix
    ./nginx.nix
    ./otg.nix
    ./pst.nix
    ./tc358743.nix
    ./vnc.nix
    ./webterm.nix
  ];

  options.services.kvmd = {
    enable = lib.mkEnableOption "the PiKVM (kvmd) daemon stack";

    package = lib.mkOption {
      type = lib.types.package;
      default = kvmdPackages.${pkgs.stdenv.hostPlatform.system}.kvmd.override {
        enableWebterm = cfg.webterm.enable;
      };
      defaultText = lib.literalExpression "the flake's kvmd package for this system (webterm assets follow services.kvmd.webterm.enable)";
      description = "The kvmd package to use.";
    };

    variant = lib.mkOption {
      type = lib.types.enum variants;
      description = "PiKVM hardware variant; selects the main config and udev rules from the package.";
    };

    hostName = lib.mkOption {
      type = lib.types.str;
      default = "_";
      description = "nginx server_name / cert CN for the kvmd virtual host.";
    };

    overrideConfig = lib.mkOption {
      inherit (yaml) type;
      default = {};
      description = "Structured /etc/kvmd/override.yaml content (your site config).";
    };

    metaConfig = lib.mkOption {
      inherit (yaml) type;
      default = {server.host = "@auto";};
      description = "Structured /etc/kvmd/meta.yaml content.";
    };

    webCss = lib.mkOption {
      type = lib.types.path;
      default = "${cfg.configsDir}/kvmd/web.css";
      defaultText = lib.literalExpression ''"''${package}/share/kvmd/configs.default/kvmd/web.css"'';
      description = "Custom /etc/kvmd/web.css.";
    };

    htpasswdFile = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.configsDir}/kvmd/htpasswd";
      defaultText = lib.literalExpression "package example htpasswd";
      description = "kvmd web auth file. The package default is the insecure upstream EXAMPLE; point this at your own (e.g. via sops/agenix).";
    };

    totpSecretFile = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.configsDir}/kvmd/totp.secret";
      defaultText = lib.literalExpression "package example (empty)";
      description = "Optional TOTP secret file for kvmd auth.";
    };

    configsDir = lib.mkOption {
      type = lib.types.str;
      internal = true;
      readOnly = true;
      default = "${cfg.package}/share/kvmd/configs.default";
      description = "kvmd's bundled configs.default tree.";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings =
      lib.optional (!builtins.elem cfg.variant testedVariants) ''
        services.kvmd.variant "${cfg.variant}" has not been hardware-validated by kvmd.nix (validated: ${lib.concatStringsSep ", " testedVariants}).
      ''
      ++ lib.optional (cfg.htpasswdFile == "${cfg.configsDir}/kvmd/htpasswd") ''
        services.kvmd.htpasswdFile is the insecure upstream EXAMPLE; set it to your own credentials file.
      '';

    environment.systemPackages = [cfg.package];

    # Auth/hardware groups shared across daemons; each daemon owns its
    # own user+group in its own file.
    users.groups = {
      kvmd-selfauth = {};
      gpio = {};
    };

    environment.etc = {
      "kvmd/override.yaml".source = overrideYaml;
      # Point kvmd at the configured files directly instead of
      # materialising them at kvmd's hardcoded /etc/kvmd defaults.
      "kvmd/override.d/00-nixos-paths.yaml".source = yaml.generate "00-nixos-paths.yaml" {
        kvmd = {
          auth = {
            internal.file = cfg.htpasswdFile;
            totp.secret.file = cfg.totpSecretFile;
          };
          info.meta = metaYaml;
        };
      };
    };

    services.udev.extraRules = lib.concatStringsSep "\n" [
      (builtins.readFile "${configsDir}/os/udev/common.rules")
      (builtins.readFile "${configsDir}/os/udev/${cfg.variant}.rules")
      ''SUBSYSTEM=="gpio", KERNEL=="gpiochip[0-9]*", GROUP="gpio", MODE="0660"''
    ];

    systemd.tmpfiles.rules = [
      "d /run/kvmd 0775 kvmd kvmd -"
      "L+ /usr/lib/kvmd/main.yaml - - - - ${mainYaml}"
      "d /var/lib/kvmd 0755 root root -"
    ];
  };
}

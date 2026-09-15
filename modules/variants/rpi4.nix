{
  config,
  lib,
  pkgs,
  kvmdPackages,
  ...
}: let
  patchDir = "${kvmdPackages.${pkgs.stdenv.hostPlatform.system}.pikvm-packages}/packages/linux-rpi-pikvm";
  pikvmKernelPatches = [
    {
      name = "pikvm-hid-clean-set-report-buf";
      patch = "${patchDir}/1001-pikvm-hid-clean-set_report_buf-on-hidg-disabling.patch";
    }
    {
      name = "pikvm-hid-remote-wakeup";
      patch = "${patchDir}/1002-pikvm-hid-remote-wakeup-support.patch";
    }
    {
      name = "pikvm-hid-remove-string-ids";
      patch = "${patchDir}/1003-pikvm-gadget-hid-Remove-string-IDs.patch";
    }
    {
      name = "pikvm-msd-inquiry-flash-cdrom";
      patch = "${patchDir}/1101-pikvm-msd-inquiry-for-flash-and-cdrom.patch";
    }
    {
      name = "pikvm-msd-dvd-support";
      patch = "${patchDir}/1102-pikvm-msd-dvd-support.patch";
    }
    {
      name = "pikvm-msd-remove-string-ids";
      patch = "${patchDir}/1103-pikvm-gadget-msd-Remove-string-IDs.patch";
    }
  ];
  # Official PiKVM patches for USB audio, unprivileged NBD and HDMI lane
  # handling; not V3 boot prerequisites. nixos-raspberrypi does not supply
  # these. Keep the existing V2 patch selection unchanged.
  v3KernelPatches =
    map (name: {
      inherit name;
      patch = "${patchDir}/${name}.patch";
    }) [
      "1201-pikvm-uac-fixed-uninitialized-set_audio"
      "1202-pikvm-uac-remove-string-ids"
      "1401-pikvm-nbd-fine-tuning"
      "1501-pikvm-tc358743-lanes-diagnostics"
      "1502-pikvm-tc358743-better-lanes-calculation"
    ];
in {
  hardware = {
    raspberry-pi.config.all = {
      dt-overlays."dwc2" = {
        enable = true;
        params = {
          dr_mode = {
            enable = true;
            value = "peripheral";
          };
        };
      };
    };
  };

  boot.kernelModules = ["dwc2"];
  boot.kernelPatches =
    pikvmKernelPatches
    ++ lib.optionals (config.services.kvmd.variant == "v3-hdmi-rpi4") v3KernelPatches;

  # /dev/vcio defaults to root-only 0600; kvmd runs unprivileged and needs
  # it (via vcgencmd) for throttle/under-voltage health. Standard RPi OS rule.
  services.udev.extraRules = ''
    KERNEL=="vcio", GROUP="video", MODE="0660"
  '';
}

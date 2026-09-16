{
  pkgs,
  kvmdPackages,
  ...
}: let
  patchDir = "${kvmdPackages.${pkgs.stdenv.hostPlatform.system}.pikvm-packages}/packages/linux-rpi-pikvm";
  # Share the official PiKVM patches across variants, as PiKVM OS does,
  # so all Pi 4 profiles use the same kernel build and cache entry.
  pikvmKernelPatches =
    map (name: {
      inherit name;
      patch = "${patchDir}/${name}.patch";
    }) [
      "1001-pikvm-hid-clean-set_report_buf-on-hidg-disabling"
      "1002-pikvm-hid-remote-wakeup-support"
      "1003-pikvm-gadget-hid-Remove-string-IDs"
      "1101-pikvm-msd-inquiry-for-flash-and-cdrom"
      "1102-pikvm-msd-dvd-support"
      "1103-pikvm-gadget-msd-Remove-string-IDs"
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
  boot.kernelPatches = pikvmKernelPatches;

  # /dev/vcio defaults to root-only 0600; kvmd runs unprivileged and needs
  # it (via vcgencmd) for throttle/under-voltage health. Standard RPi OS rule.
  services.udev.extraRules = ''
    KERNEL=="vcio", GROUP="video", MODE="0660"
  '';
}

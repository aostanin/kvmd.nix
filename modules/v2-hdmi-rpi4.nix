{
  pkgs,
  inputs,
  ...
}: let
  patchDir = "${inputs.pikvm-packages}/packages/linux-rpi-pikvm";
  pikvmKernelPatches = [
    {
      name = "pikvm-hid-remote-wakeup";
      patch = "${patchDir}/1001-pikvm-hid-remote-wakeup-support.patch";
    }
    {
      name = "pikvm-hid-clean-set-report-buf";
      patch = "${patchDir}/1002-pikvm-hid-clean-set_report_buf-on-hidg-disabling.patch";
    }
    {
      name = "pikvm-msd-dvd-support";
      patch = "${patchDir}/2001-pikvm-msd-dvd-support.patch";
    }
    {
      name = "pikvm-msd-inquiry-flash-cdrom";
      patch = "${patchDir}/2002-pikvm-msd-inquiry-for-flash-and-cdrom.patch";
    }
  ];
in {
  hardware.raspberry-pi."4" = {
    tc358743.enable = true;
    dwc2 = {
      enable = true;
      dr_mode = "peripheral";
    };
  };

  boot.kernelModules = ["dwc2" "tc358743"];
  boot.kernelParams = ["cma=192M"];

  # nixos-hardware's kernel.nix ignores boot.kernelPatches; patches must
  # go through argsOverride (nixos-hardware#1745).
  boot.kernelPackages = let
    baseKernel = pkgs.callPackage "${inputs.nixos-hardware}/raspberry-pi/common/kernel.nix" {rpiVersion = 4;};
  in
    pkgs.linuxPackagesFor (baseKernel.override {
      argsOverride.kernelPatches = baseKernel.kernelPatches ++ pikvmKernelPatches;
    });

  # /dev/vcio defaults to root-only 0600; kvmd runs unprivileged and needs
  # it (via vcgencmd) for throttle/under-voltage health. Standard RPi OS rule.
  services.udev.extraRules = ''
    KERNEL=="vcio", GROUP="video", MODE="0660"
  '';
}

{
  pkgs,
  kvmdPackages,
  kvmdNixosHardware,
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
      name = "pikvm-msd-inquiry-flash-cdrom";
      patch = "${patchDir}/1101-pikvm-msd-inquiry-for-flash-and-cdrom.patch";
    }
    {
      name = "pikvm-msd-dvd-support";
      patch = "${patchDir}/1102-pikvm-msd-dvd-support.patch";
    }
  ];
in {
  hardware.raspberry-pi."4".dwc2 = {
    enable = true;
    dr_mode = "peripheral";
  };

  boot.kernelModules = ["dwc2"];

  # nixos-hardware's kernel.nix ignores boot.kernelPatches; patches must
  # go through argsOverride (nixos-hardware#1745).
  boot.kernelPackages = let
    baseKernel = pkgs.callPackage "${kvmdNixosHardware}/raspberry-pi/common/kernel.nix" {rpiVersion = 4;};
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

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
in {
  # nixos-hardware mkForces sdImage.populateFirmwareCommands whenever an
  # sd-image module is imported, gated on neither firmware.enable nor this, so
  # uboot.enable is what keeps kernel=u-boot.bin in the image's config.txt.
  # Leave firmware.enable off: its activation script rewrites the whole
  # partition through temp files on every switch, needing headroom equal to its
  # largest file (~4.8M) on top of a ~25M payload, which does not fit the 30M
  # sdImage.firmwareSize.
  hardware.raspberry-pi.firmware.uboot.enable = true;

  # uboot.enable defaults this off, which drops extlinux's FDTDIR and leaves
  # U-Boot on the bare firmware device tree. The overlays below are build-time,
  # so U-Boot has to keep loading the generation's device tree.
  boot.loader.generic-extlinux-compatible.useGenerationDeviceTree = true;

  # nixos-hardware removed its dwc2 module in favour of the stock firmware
  # overlay, which would need that activation script. Keep the overlay
  # build-time instead, where it lands in the generation device tree.
  # Values match the stock dwc2.dtbo.
  hardware.deviceTree.overlays = [
    {
      name = "dwc2-overlay";
      dtsText = ''
        /dts-v1/;
        /plugin/;

        / {
          compatible = "brcm,bcm2711";

          fragment@0 {
            target = <&usb>;
            #address-cells = <1>;
            #size-cells = <1>;

            __overlay__ {
              compatible = "brcm,bcm2835-usb";
              dr_mode = "peripheral";
              g-np-tx-fifo-size = <32>;
              g-rx-fifo-size = <558>;
              g-tx-fifo-size = <512 512 512 512 512 256 256>;
              status = "okay";
            };
          };
        };
      '';
    }
  ];

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

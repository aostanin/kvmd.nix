{
  modulesPath,
  lib,
  ...
}: {
  imports = ["${modulesPath}/installer/sd-card/sd-image-aarch64.nix"];

  networking = {
    hostName = "pikvm";
    useDHCP = lib.mkDefault true;
  };

  users.users.root.initialPassword = "pikvm";

  services = {
    kvmd = {
      enable = true;
      janus.enable = true;
      msd.enable = true;
    };

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
      };
    };

    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
      };
    };
  };

  # sd-image-aarch64's cross-SBC initrd list FATALs on modules the rpi
  # kernel lacks; force the minimal set it actually has.
  boot.initrd.availableKernelModules = lib.mkForce [
    "ext4"
    "mmc_block"
    "usbhid"
    "usb_storage"
    "xhci_hcd"
    "vc4"
    "pcie-brcmstb"
    "reset-raspberrypi"
  ];

  boot.supportedFilesystems.zfs = lib.mkForce false;
  documentation.enable = lib.mkDefault false;

  system.stateVersion = "25.11";
}

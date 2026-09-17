{
  nixos-raspberrypi,
  lib,
  ...
}: {
  # With the Raspberry Pi base, the inherited initrd module list includes
  # ext4, mmc_block, usbhid, usb_storage, xhci_hcd, vc4, pcie-brcmstb and
  # reset-raspberrypi for both V2 profiles and V3. No mkForce list is needed
  # here: using the defaults retains those drivers rather than removing them.
  imports = [nixos-raspberrypi.nixosModules.sd-image];

  networking = {
    hostName = "pikvm";
    useDHCP = lib.mkDefault true;
  };

  users.users.root.initialPassword = "pikvm";

  services = {
    kvmd = {
      enable = true;
      janus.enable = true;
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

  boot.supportedFilesystems.zfs = lib.mkForce false;
  documentation.enable = lib.mkDefault false;

  system.stateVersion = "25.11";
}

{
  imports = [./rpi4.nix];

  services.kvmd.variant = "v2-hdmiusb-rpi4";

  boot.kernelModules = ["uvcvideo"];
}

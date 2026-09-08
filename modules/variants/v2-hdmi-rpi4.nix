{
  imports = [./rpi4.nix];

  services.kvmd.variant = "v2-hdmi-rpi4";

  hardware = {
    raspberry-pi.config.all = {
      dt-overlays."tc358743".enable = true;
    };
  };

  boot.kernelModules = ["tc358743"];
  boot.kernelParams = ["cma=192M"];
}

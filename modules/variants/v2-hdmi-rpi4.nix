{
  imports = [./rpi4.nix];

  services.kvmd.variant = "v2-hdmi-rpi4";

  # nixos-hardware's tc358743 module builds its overlay into the generation
  # device tree, which U-Boot no longer loads (see rpi4.nix). The stock overlay
  # defaults match what that module produced: 2 lanes, legacy unicam.
  hardware.raspberry-pi.configtxt.deviceTreeOverlays.pi4 = [
    {tc358743 = {};}
  ];

  boot.kernelModules = ["tc358743"];
  boot.kernelParams = ["cma=192M"];
}

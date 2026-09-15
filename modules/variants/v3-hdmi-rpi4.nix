{
  config,
  lib,
  ...
}: {
  imports = [./hdmi-rpi4.nix];

  services.kvmd = {
    variant = "v3-hdmi-rpi4";
    edidHex = lib.mkDefault "${config.services.kvmd.configsDir}/kvmd/edid/v3.hex";
    fan.enable = lib.mkDefault true;
    oled.enable = lib.mkDefault true;
    watchdog.enable = lib.mkDefault true;
    janus.enable = lib.mkDefault true;
    nbd.enable = lib.mkDefault true;
  };

  # Firmware overlays survive U-Boot with the new base's default
  # useGenerationDeviceTree=false, preserving the real board revision too.
  hardware.raspberry-pi.config.all = {
    options = {
      gpu_mem = {
        enable = true;
        value = 128;
      };
      hdmi_force_hotplug = {
        enable = true;
        value = true;
      };
    };
    base-dt-params = {
      i2c_arm = {
        enable = true;
        value = "on";
      };
      # The base sets audio=on; analog audio competes for the fan's PWM.
      audio = {
        enable = true;
        value = lib.mkForce "off";
      };
      act_led_gpio = {
        enable = true;
        value = 13;
      };
    };
    dt-overlays = {
      disable-bt.enable = true;
      i2c-rtc = {
        enable = true;
        params.pcf8563.enable = true;
        params.wakeup-source.enable = true;
      };
      tc358743-audio.enable = true;
    };
  };
  boot.kernelModules = ["i2c-dev" "i2c-bcm2835" "rtc-pcf8563"];
  boot.kernelParams = ["console=ttyAMA0,115200"];
  time.hardwareClockInLocalTime = false;
}

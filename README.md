# kvmd.nix

NixOS packaging and modules for [PiKVM](https://pikvm.org)'s
[`kvmd`](https://github.com/pikvm/kvmd). Run a PiKVM on a stock NixOS Raspberry
Pi.

Not affiliated with the PiKVM project.

## Status

Two variants for the Raspberry Pi 4 are supported:

- **`v2-hdmi-rpi4`**: CSI capture via the TC358743 HDMI→CSI bridge.
- **`v2-hdmiusb-rpi4`**: USB UVC capture dongle (e.g. MS2109), on any USB port.

Both build a flashable SD image and have been tested on real hardware.

## Outputs

- `packages.${system}.{default,kvmd}`: the kvmd package (`default` is `kvmd`).
- `nixosModules.{default,kvmd}`: the daemon set (kvmd +
  otg/media/pst/janus/nginx and optional vnc/ipmi/nbd/webterm); `default` is
  `kvmd`.
- `nixosModules.<variant>` (`v2-hdmi-rpi4`, `v2-hdmiusb-rpi4`): the Pi 4
  hardware profile (kernel patches, dwc2, capture); sets
  `services.kvmd.variant`, so pair it with `nixosModules.kvmd`.
- `nixosConfigurations.<variant>`: ready-to-flash SD images.

## Quick start

Build an SD image:

```sh
nix build github:aostanin/kvmd.nix#nixosConfigurations.v2-hdmi-rpi4.config.system.build.sdImage
```

Or compose it into your own host:

```nix
{
  inputs.kvmd.url = "github:aostanin/kvmd.nix";

  outputs = { nixpkgs, kvmd, ... }: {
    nixosConfigurations.mykvm = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        kvmd.nixosModules.default
        kvmd.nixosModules.v2-hdmi-rpi4
        {
          services.kvmd = {
            enable = true;

            ocrLanguages = ["eng" "rus"];

            htpasswdFile = "/run/secrets/kvmd-htpasswd";
            vnc = {
              enable = true;
              passwordFile = "/run/secrets/kvmd-vncpasswd";
            };
            ipmi = {
              enable = true;
              passwordFile = "/run/secrets/kvmd-ipmipasswd";
            };

            overrideConfig = {
              kvmd.streamer.resolution.default = "1280x720";
            };
          };
        }
      ];
    };
  };
}
```

## Security

The `nixosConfigurations` ship **insecure defaults** for first boot. Before
putting a box on a network you must change:

- Root password (`pikvm`) and root SSH login.
- The kvmd web / VNC / IPMI credentials. These default to the **upstream example
  files** (`admin`/`admin`). Point them at your own:

```nix
services.kvmd.htpasswdFile      = "/run/secrets/kvmd-htpasswd";   # user:{SSHA512}…
services.kvmd.vnc.passwordFile  = "/run/secrets/kvmd-vncpasswd";  # plaintext, one per line
services.kvmd.ipmi.passwordFile = "/run/secrets/kvmd-ipmipasswd"; # login:password
```

## License

This repository's Nix code is MIT (see [LICENSE](LICENSE)). It only packages and
configures upstream software consumed as flake inputs:

- [`pikvm/kvmd`](https://github.com/pikvm/kvmd): GPL-3.0-or-later, © Maxim
  Devaev; the resulting `kvmd` package is therefore GPL-3.0-or-later.
- [`pikvm/packages`](https://github.com/pikvm/packages): kernel and janus.js
  patches applied to the RPi kernel / Janus assets.

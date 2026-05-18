{
  lib,
  stdenv,
  python314,
  ustreamer,
  janus-gateway,
  iproute2,
  iptables,
  procps,
  systemd,
  dnsmasq,
  ipmitool,
  v4l-utils,
  nbd,
  coreutils,
  writeText,
  runCommand,
  fetchurl,
  glibc,
  libxkbcommon,
  tesseract,
  libraspberrypi,
  pikvm-kvmd,
  pikvm-packages,
  enableWebterm ? true,
  ocrLanguages ? ["eng"],
}: let
  python = python314;

  tesseractOcr = tesseract.override {enableLanguages = ocrLanguages;};
  v4lUtilsCli = v4l-utils.override {withGUI = false;};

  # kvmd's patched fstab.py reads this to discover the MSD/PST stores.
  fstabFile = writeText "kvmd-fstab" ''
    none /var/lib/kvmd/msd none rw,X-kvmd.otgmsd-user=kvmd 0 0
    none /var/lib/kvmd/pst none rw,X-kvmd.pst-user=kvmd-pst,X-kvmd.pst-group=kvmd-pst 0 0
  '';

  webrtcAdapter = fetchurl {
    url = "https://raw.githubusercontent.com/webrtcHacks/adapter/v9.0.1/release/adapter.js";
    hash = "sha256-qJ4ou0JzcZYb0z+094G11tQBAHOuYgP5G2qTTyYvzDw=";
  };
  # kvmd needs PiKVM's janus-gateway-pikvm 0001-js.patch on janus.js.
  janusAssets = runCommand "kvmd-janus-assets" {} ''
    mkdir -p $out
    cp ${janus-gateway.src}/html/demos/janus.js $out/janus.js
    cp ${webrtcAdapter} $out/adapter.js
    chmod +w $out/janus.js
    patch $out/janus.js < ${pikvm-packages}/packages/janus-gateway-pikvm/0001-js.patch
  '';

  # deps mirror the Arch PKGBUILD; kvmd's setup.py declares none
  kvmdPythonDeps = ps:
    with ps; [
      aiofiles
      aiohttp
      async-lru
      bcrypt
      dbus-next
      dbus-python
      evdev
      hidapi
      libgpiod
      mako
      netifaces
      passlib
      pillow
      psutil
      pygments
      pyghmi
      pyotp
      pyrad
      pyserial
      pyserial-asyncio
      pyudev
      pyusb
      python-ldap
      python-pam
      pyyaml
      qrcode
      ruamel-yaml
      setproctitle
      six
      spidev
      systemd-python
      xlib
      zstandard
    ];

  # ustreamer's python C-extension lives in the µStreamer tree, not nixpkgs
  ustreamer-python = python.pkgs.buildPythonPackage {
    pname = "ustreamer";
    inherit (ustreamer) version src;
    format = "setuptools";
    sourceRoot = "${ustreamer.src.name}/python";
    pythonImportsCheck = ["ustreamer"];
  };

  allPythonDeps = ps: kvmdPythonDeps ps ++ [ustreamer-python];

  tools = {
    ustreamer = lib.getExe ustreamer;
    janus = lib.getExe' janus-gateway "janus";
    ip = lib.getExe' iproute2 "ip";
    iptables = lib.getExe' iptables "iptables";
    sysctl = lib.getExe' procps "sysctl";
    systemctl = lib.getExe' systemd "systemctl";
    systemd-run = lib.getExe' systemd "systemd-run";
    dnsmasq = lib.getExe' dnsmasq "dnsmasq";
    ipmitool = lib.getExe' ipmitool "ipmitool";
    v4l2-ctl = lib.getExe' v4lUtilsCli "v4l2-ctl";
    nbd-client = lib.getExe' nbd "nbd-client";
    true = lib.getExe' coreutils "true";
    libc = "${glibc}/lib/libc.so.6";
    libxkbcommon = "${libxkbcommon}/lib/libxkbcommon.so.0";
    libtesseract = "${tesseractOcr}/lib/libtesseract.so.5";
  };
in
  python.pkgs.buildPythonApplication {
    pname = "kvmd";
    version = "4.168";
    format = "setuptools";

    src = pikvm-kvmd;

    propagatedBuildInputs = allPythonDeps python.pkgs;

    pythonImportsCheck = ["kvmd" "kvmd.apps.kvmd"];

    postPatch =
      ''
        # ctypes.util.find_library is broken under Nix (NixOS #7307)
        substituteInPlace kvmd/libc.py \
          --replace-fail 'ctypes.util.find_library("c")' '"${tools.libc}"'
        substituteInPlace kvmd/keyboard/printer.py \
          --replace-fail 'ctypes.util.find_library("xkbcommon")' '"${tools.libxkbcommon}"'
        substituteInPlace kvmd/apps/kvmd/ocr.py \
          --replace-fail 'ctypes.util.find_library("tesseract")' '"${tools.libtesseract}"'

        substituteInPlace kvmd/apps/_scheme.py \
          --replace-quiet '"/usr/bin/ip"'          '"${tools.ip}"' \
          --replace-quiet '"/usr/sbin/iptables"'   '"${tools.iptables}"' \
          --replace-quiet '"/usr/sbin/sysctl"'     '"${tools.sysctl}"' \
          --replace-quiet '"/usr/bin/systemctl"'   '"${tools.systemctl}"' \
          --replace-quiet '"/usr/bin/systemd-run"' '"${tools.systemd-run}"' \
          --replace-quiet '"/usr/sbin/dnsmasq"'    '"${tools.dnsmasq}"' \
          --replace-quiet '"/usr/bin/janus"'       '"${tools.janus}"' \
          --replace-quiet '"/usr/bin/nbd-client"'  '"${tools.nbd-client}"' \
          --replace-quiet '"/usr/bin/sudo"'        '"/run/wrappers/bin/sudo"' \
          --replace-quiet '"/bin/true"'            '"${tools.true}"'

        substituteInPlace kvmd/plugins/ugpio/ipmi.py \
          --replace-quiet '"/usr/bin/ipmitool"' '"${tools.ipmitool}"'
        substituteInPlace kvmd/apps/edidconf/__init__.py \
          --replace-quiet '"/usr/bin/v4l2-ctl"' '"${tools.v4l2-ctl}"'
        # MSD/PST are plain dirs on the rw root; kvmd's only mount call is
        # the RO/RW remount, which has nothing to toggle -> point it at true.
        substituteInPlace kvmd/helpers/remount/__init__.py \
          --replace-quiet '"/bin/mount"' '"${tools.true}"'
        substituteInPlace kvmd/fstab.py \
          --replace-fail 'f"{env.ETC_PREFIX}/etc/fstab"' '"${fstabFile}"'

        substituteInPlace configs/kvmd/main/*.yaml \
          --replace-quiet '/usr/bin/ustreamer' '${tools.ustreamer}'
      ''
      + lib.optionalString stdenv.hostPlatform.isAarch64 ''
        substituteInPlace kvmd/apps/_scheme.py \
          --replace-quiet '"/usr/bin/vcgencmd"' '"${libraspberrypi}/bin/vcgencmd"'
      ''
      + ''
        substituteInPlace kvmd/apps/_scheme.py \
          --replace-quiet '"/usr/share/kvmd/extras"'        "\"$out/share/kvmd/extras\"" \
          --replace-quiet '"/usr/share/kvmd/keymaps/en-us"' "\"$out/share/kvmd/keymaps/en-us\"" \
          --replace-quiet '"/usr/share/tessdata"'           '"${tesseractOcr}/share/tessdata"' \
          --replace-quiet '"/usr/bin/kvmd-helper-pst-remount"' "\"$out/bin/kvmd-helper-pst-remount\""
        substituteInPlace kvmd/plugins/msd/otg/__init__.py \
          --replace-quiet '"/usr/bin/sudo"' '"/run/wrappers/bin/sudo"' \
          --replace-quiet '"/usr/bin/kvmd-helper-otgmsd-remount"' "\"$out/bin/kvmd-helper-otgmsd-remount\""
        substituteInPlace kvmd/apps/edidconf/__init__.py \
          --replace-quiet '/usr/share/kvmd/configs.default/kvmd/edid' "$out/share/kvmd/configs.default/kvmd/edid"

        substituteInPlace configs/nginx/kvmd.ctx-server.conf \
          --replace-quiet '/usr/share/kvmd/web' "$out/share/kvmd/web"

        # kvmd-udev-hdmiusb-check enforces PiKVM's documented "use a
        # specific USB port for the capture dongle" rule before creating
        # kvmd-video. Point it at `true` so kvmd-video binds on any port.
        for f in configs/os/udev/*.rules; do
          substituteInPlace "$f" \
            --replace-quiet /usr/bin/kvmd-udev-hdmiusb-check ${tools.true}
        done
      '';

    postInstall = ''
      share=$out/share/kvmd
      mkdir -p "$share"
      cp -r web extras hid switch "$share/"
      cp -r contrib/keymaps "$share/keymaps"
      cp -r configs "$share/configs.default"
      find "$share/web" -name '*.pug' -delete
      ${lib.optionalString enableWebterm ''
        # kvmd-webterm assets (ttyd "Terminal" extra) from pikvm/packages.
        wt=${pikvm-packages}/packages/kvmd-webterm
        install -Dm644 -t "$share/web/extras/webterm" "$wt/terminal.svg"
        install -Dm644 -t "$share/extras/webterm" "$wt/manifest.yaml" "$wt"/nginx.ctx-*.conf
      ''}
    '';

    passthru = {
      v4l-utils = v4lUtilsCli;
      inherit janusAssets;
    };

    meta = {
      description = "The main PiKVM daemon";
      homepage = "https://github.com/pikvm/kvmd";
      license = lib.licenses.gpl3Plus;
      platforms = lib.platforms.linux;
      mainProgram = "kvmd";
    };
  }

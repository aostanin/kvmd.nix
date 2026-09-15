{
  lib,
  stdenv,
  fetchFromGitHub,
  iniparser,
  libmicrohttpd,
  libgpiod,
  wiringpi,
  nix-update-script,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "kvmd-fan";
  version = "0.33";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "kvmd-fan";
    tag = "v${finalAttrs.version}";
    hash = "sha256-yoQQAYP5/P9/gsD35EvECtJ+AdHvjgOw/OeiXwmJ+gg=";
  };

  buildInputs = [
    iniparser
    libmicrohttpd
    libgpiod
    wiringpi.wiringPi
  ];
  makeFlags = ["PREFIX=$(out)"];
  enableParallelBuilding = true;

  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/kvmd-fan --help > /dev/null
    runHook postInstallCheck
  '';

  passthru.updateScript = nix-update-script {extraArgs = ["--flake"];};

  meta = {
    description = "PiKVM fan controller";
    homepage = "https://github.com/pikvm/kvmd-fan";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "kvmd-fan";
  };
})

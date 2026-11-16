{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-11-14";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "aeccd69a1791112bf2a8a3f2f40e3f53204177d5";
    hash = "sha256-O6LhlywJBQTzFBBhcjSARGIFLehblS+iot+0dOjYp+Q=";
  };

  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    cp -a . "$out"
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {extraArgs = ["--flake" "--version=branch"];};
}

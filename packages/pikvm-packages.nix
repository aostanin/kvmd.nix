{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-06-11";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "526ff57d81540b2b7d5f83114b8594d8e18ce921";
    hash = "sha256-mpz7BKbwyycbSt412bDFDrFvcJdBdMru7ae6hRoVgos=";
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

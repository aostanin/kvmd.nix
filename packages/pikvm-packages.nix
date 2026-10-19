{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-10-17";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "7e829a3910912e9354bd132e9f3c22a9012d3477";
    hash = "sha256-v7T3maRX/IYTwUgpAS6tmVX/GhuRqTfBu+ZKKoSEMVw=";
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

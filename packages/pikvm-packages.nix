{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-10-24";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "40a214e09ad014a6c8abfe0494cd3358bbf2c2ab";
    hash = "sha256-K2FqXPIqsbC4fVQyFZINmdblRVwfcU3tpLb7s0+qc/Y=";
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

{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-10-30";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "ba0021128f3e73dea3fb9dc3cb335b549ed646d8";
    hash = "sha256-+gadVO2gtO16ju4kiOOeY0WYQCffZFtQiV/LewV7zRs=";
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

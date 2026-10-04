{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-10-03";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "272d2baa3be6c9b571059bee2dee6faf0eeb4c87";
    hash = "sha256-BOFTUFtOsXmLd4FlShEY/43QwaF2WXAWn7UiKMshwOI=";
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

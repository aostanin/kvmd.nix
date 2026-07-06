{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-07-02";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "e422cd84e1a75543c3de993a4a0174e8a4c81d59";
    hash = "sha256-pQTilrRFwf2UXpCDAupJbLVEPsCicMiBHgZh75qpGVk=";
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

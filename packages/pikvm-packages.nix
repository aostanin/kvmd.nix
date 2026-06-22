{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-06-20";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "ee423a3fa3539bdb512a6a61c493c8ca11a519cb";
    hash = "sha256-O4m+JxyfOf4JQzqUI+kXBY6aZ/ShaCZ0RYmcmA0DxYM=";
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

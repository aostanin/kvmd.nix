{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-09-10";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "0ba34d3d6e0933c6b5dbecf00466f3e191e8bbd8";
    hash = "sha256-FtZ+MN6icDdemCodyX1TxyRU2vHvvv5w53d0oZjLRSE=";
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

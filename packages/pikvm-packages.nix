{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-05-30";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "2ba71b333084d8e02d718fe682574ca0975a9d78";
    hash = "sha256-lYR1v7so7jYQb47BqB77/3uBsPfA8LGmvfWi3rISvBY=";
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

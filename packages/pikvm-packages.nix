{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-05-31";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "d2d6f82bc9b5d9b5c6249e7fe2e0859d13e54741";
    hash = "sha256-1RFsInq8aNdiQOheCoVJSSe+ShY7jBpae4TeIicb5Ek=";
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

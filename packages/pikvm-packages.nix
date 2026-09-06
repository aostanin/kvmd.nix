{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-08-31";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "04c46e088be8bdba4fa38bb15b8fe2e3c6b9e359";
    hash = "sha256-Z99I5sXISPGlA64EE44NNWqEoEKKAqNA7IiyWUahtwE=";
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

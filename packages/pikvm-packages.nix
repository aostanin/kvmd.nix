{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-07-18";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "500fd85bf9f208998f97032103e89e90503de51d";
    hash = "sha256-r6WpKsykbk3pwgyhJadRYwP7de6ZrYqYrfGLUJ9l2PE=";
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

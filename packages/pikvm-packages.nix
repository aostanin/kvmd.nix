{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-08-06";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "e42612d7cbc67d77558893b67b5c76d271993d2e";
    hash = "sha256-UnoUu5KU7dbjl7i750y43oO1JwKKIYc6RThTG1ha+wo=";
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

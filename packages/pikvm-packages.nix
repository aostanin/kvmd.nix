{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-11-01";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "b7b7f5760dbadd17d160222c855a95c410e3e6e7";
    hash = "sha256-PQa2mDF2KH89unMxrLfpR6FT1r6woZt7W7KPdNYE78Q=";
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

{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-10-07";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "9dafa045316a2907819561d03fcb23314e274dbb";
    hash = "sha256-qR0ELsJ/mtLa8WvI0cf+T1FQ3/kT3+mQpdb3u/hS8o4=";
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

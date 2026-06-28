{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-06-26";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "33dff548fa2fe2986b72cf0af3efa07985f0faf2";
    hash = "sha256-+T+rYlA2i5E9bAmmqK+bbY0Lx80tFn8LEMvjE1o1Ock=";
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

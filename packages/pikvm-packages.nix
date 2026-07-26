{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-07-24";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "5e87241398d3ca9bd01d20a740218229ac4f485d";
    hash = "sha256-M2W1VeFWcwJgok2pGfNoZJWdCLMOFul94GBmy68V6ps=";
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

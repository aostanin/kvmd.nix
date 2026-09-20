{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-09-19";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "ab73e13d5cb4490e6b0d7c07efe3911ee4ff0bad";
    hash = "sha256-45sSfIRteFbeP9/9JX1Bb0xHu9YLN+oQjI54J9JV8cA=";
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

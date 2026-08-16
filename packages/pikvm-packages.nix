{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-08-16";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "083e672edfd00146186ba73f24e5d5f3d0a74a23";
    hash = "sha256-aOSe636cPLVlUvHJcUkEql5W0dsw0a9FyDNhrViXuyY=";
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

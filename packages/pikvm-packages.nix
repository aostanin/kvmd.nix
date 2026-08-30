{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-08-29";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "314cc6c36d722ffbd95aab0dd1af3cf934614ccd";
    hash = "sha256-xeEn6yBPdpaHoCmCt74gXOfBcn9rmvf+mdJ3nwfL6Qk=";
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

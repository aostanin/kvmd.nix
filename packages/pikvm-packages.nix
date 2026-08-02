{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-08-02";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "a5ff0d357f5087ac419df508cb7a3e53e4933dbb";
    hash = "sha256-EEtikd01IguVsshviIPYj6IFcnk0dhjmmmRDvcBJsdU=";
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

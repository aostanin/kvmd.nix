{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "pikvm-packages";
  version = "0-unstable-2026-06-06";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "packages";
    rev = "e257cd4a55a01747657b2db6c67e75d01ffd5473";
    hash = "sha256-KeBfdY2etINC2KmsXS3j5FfPwtBFa19/ZtrLHrPo42c=";
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

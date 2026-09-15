{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  luma-core,
}:
buildPythonPackage rec {
  pname = "luma-oled";
  version = "3.15.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "rm-hull";
    repo = "luma.oled";
    tag = version;
    hash = "sha256-+8WEMhdldIPnI5F6dAKkCv9qoX3JowNRyWy1EHygUzo=";
  };

  build-system = [setuptools];
  dependencies = [luma-core];
  pythonImportsCheck = ["luma.oled.device"];

  meta = {
    description = "Python drivers for OLED displays";
    homepage = "https://github.com/rm-hull/luma.oled";
    license = lib.licenses.mit;
  };
}

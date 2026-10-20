{
  lib,
  python3Packages,
  fetchPypi,
}:
python3Packages.buildPythonApplication rec {
  pname = "lightroom-cli";
  version = "1.2.2";
  pyproject = true;

  src = fetchPypi {
    pname = "lightroom_cli";
    inherit version;
    hash = "sha256-+80a7lIRiXeMkqqegAoLD59IX9wV6kTTD17V44Eqmis=";
  };

  build-system = with python3Packages; [setuptools wheel];

  dependencies = with python3Packages; [
    click
    rich
    pydantic
    platformdirs
    fastmcp
  ];

  pythonImportsCheck = ["cli.main" "lightroom_sdk"];

  meta = {
    description = "CLI bridge for Adobe Lightroom Classic";
    homepage = "https://github.com/znznzna/lightroom-cli";
    license = lib.licenses.mit;
    mainProgram = "lr";
  };
}

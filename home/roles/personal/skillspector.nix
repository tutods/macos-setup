{
  lib,
  python3Packages,
  fetchFromGitHub,
  fetchPypi,
}: let
  pywhatwgurl = python3Packages.buildPythonPackage rec {
    pname = "pywhatwgurl";
    version = "0.1.1";
    format = "wheel";

    src = fetchPypi {
      inherit pname version format;
      dist = "py3";
      python = "py3";
      hash = "sha256-1nBy0/cC+Jnm5d4HTn+hS1ycXIX2FsYBbE7vnJQRPV8=";
    };

    dependencies = with python3Packages; [idna];

    pythonImportsCheck = ["pywhatwgurl"];

    meta = {
      description = "Python implementation of the WHATWG URL standard";
      homepage = "https://pypi.org/project/pywhatwgurl/";
    };
  };
in
  python3Packages.buildPythonApplication {
    pname = "skillspector";
    version = "2.13.4";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "NVIDIA";
      repo = "SkillSpector";
      rev = "54824463814a0be01360792523ec7245a69190fc";
      hash = "sha256-TVrrqTCrjNU7F9uOBvW1EKuMfExATpOLStBZSqvwmx8=";
    };

    build-system = with python3Packages; [hatchling];

    # upstream pins exact versions newer than nixpkgs; the older ones are API-compatible for the CLI
    pythonRelaxDeps = ["typer" "regex" "langchain-anthropic"];

    dependencies = with python3Packages; [
      typer
      rich
      httpx
      pywhatwgurl
      regex
      tree-sitter
      tree-sitter-javascript
      packaging
      pyyaml
      pydantic
      openai
      langgraph
      langchain-anthropic
      langchain-aws
      langchain-core
      langchain-openai
      boto3
      langsmith
      yara-python
    ];

    pythonImportsCheck = ["skillspector"];

    meta = {
      description = "Security scanner for AI agent skills";
      homepage = "https://github.com/NVIDIA/SkillSpector";
      license = lib.licenses.asl20;
      mainProgram = "skillspector";
    };
  }

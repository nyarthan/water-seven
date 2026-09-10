{
  ast-grep,
  cargo,
  fetchPypi,
  lib,
  python313Packages,
  rustc,
  rustPlatform,
  versionCheckHook,
}:
python313Packages.buildPythonApplication (finalAttrs: {
  pname = "headroom-ai";
  version = "0.37.0";
  pyproject = true;

  src = fetchPypi {
    pname = "headroom_ai";
    inherit (finalAttrs) version;
    hash = "sha256-f/3supHORN0C8WAUmfbJNcRzdLfLbsYeVpuBaku3iiY=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname version src;
    hash = "sha256-iEvap6uLsAqCSv+l/S7K7osxL+yV7Y8pE6Dhaqt2AIA=";
  };

  build-system = [
    cargo
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
    rustc
  ];

  dependencies = with python313Packages; [
    click
    litellm
    opentelemetry-api
    pydantic
    pyyaml
    rich
    tiktoken
    tomlkit
  ];

  pythonRemoveDeps = [ "ast-grep-cli" ];
  makeWrapperArgs = [
    "--prefix PATH : ${lib.makeBinPath [ ast-grep ]}"
  ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "Token optimization framework for AI applications";
    homepage = "https://headroom-docs.vercel.app";
    license = lib.licenses.asl20;
    mainProgram = "headroom";
  };
})

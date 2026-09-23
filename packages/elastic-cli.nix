{
  buildNpmPackage,
  lib,
  nodejs_24,
}:
buildNpmPackage rec {
  pname = "elastic-cli";
  version = "0.5.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./elastic-cli-package.json
      ./elastic-cli-package-lock.json
    ];
  };

  postPatch = ''
    cp elastic-cli-package.json package.json
    cp elastic-cli-package-lock.json package-lock.json
  '';

  npmDepsHash = "sha256-ldtgIXkzuxj6E0lVdXtA7wQIK1oR/0QhQ6u4L44AIok=";
  nodejs = nodejs_24;
  dontNpmBuild = true;

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    export HOME="$TMPDIR"
    "$out/bin/elastic" --version | grep -Fx "${version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "Command-line interface for the Elastic Stack and Elastic Cloud";
    homepage = "https://www.elastic.co/docs/reference/elastic-cli";
    license = lib.licenses.asl20;
    mainProgram = "elastic";
  };
}

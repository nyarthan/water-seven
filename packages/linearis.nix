{
  buildNpmPackage,
  fetchurl,
  lib,
}:
buildNpmPackage rec {
  pname = "linearis";
  version = "2026.8.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/linearis/-/linearis-${version}.tgz";
    hash = "sha256-oMgGZ2s4oA9NOmpQ+1iM0yeyLOxEVX9o7KxQ9mnAhIU=";
  };

  postPatch = ''
    cp ${./linearis-package-lock.json} package-lock.json
  '';
  npmDepsHash = "sha256-wFxbcVIoGP7LlIhzXzy+wUvx/xtL69sCdpyfQ6B3bCI=";
  dontNpmBuild = true;

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    export HOME="$TMPDIR"
    "$out/bin/linearis" --version | grep -F "${version}"
    "$out/bin/linear" --version | grep -F "${version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "Structured command-line interface for Linear";
    homepage = "https://github.com/linearis-oss/linearis";
    license = lib.licenses.mit;
    mainProgram = "linearis";
  };
}

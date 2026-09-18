{
  lib,
  stdenvNoCC,
  fetchPnpmDeps,
  pnpmConfigHook,
  pnpm_11,
  nodejs_24,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "water-seven-pi-resources";
  version = "1";

  src = lib.fileset.toSource {
    root = ../native/pi;
    fileset = lib.fileset.unions [
      ../native/pi/extensions
      ../native/pi/package.json
      ../native/pi/pnpm-lock.yaml
      ../native/pi/pnpm-workspace.yaml
      ../native/pi/themes
      ../native/pi/tsconfig.json
    ];
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_11;
    fetcherVersion = 3;
    hash = "sha256-OVLFUORsKH/68r59wNZma246iLCwzWfy5gzFQYFI8Ss=";
  };

  nativeBuildInputs = [
    nodejs_24
    pnpmConfigHook
    pnpm_11
  ];

  buildPhase = ''
    runHook preBuild
    pnpm types
    pnpm prune --prod --ignore-scripts
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -R extensions themes node_modules package.json "$out/"
    runHook postInstall
  '';
})

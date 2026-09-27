{
  autoPatchelfHook,
  fetchurl,
  lib,
  stdenv,
}:
let
  version = "1.3.1";
  artifacts = {
    aarch64-darwin = {
      platform = "darwin-arm64";
      hash = "sha256-B8CCRN1+Q1gJ+TVvaaZF5HtkPngCTrd0yQK9rT3woaw=";
    };
    x86_64-darwin = {
      platform = "darwin-x64";
      hash = "sha256-dYh+1JWCafvneWbfWa2kLfO4X0suSPf4GJ97cnhEnEg=";
    };
    aarch64-linux = {
      platform = "linux-arm64";
      hash = "sha256-Cmz1v98mMIYzb+WI0Sjhtace/LvTqnjebfJoSctNLww=";
    };
    x86_64-linux = {
      platform = "linux-x64";
      hash = "sha256-8Vi8BgkxP+cWsZ2casoKjn+HoOJRzvDLdwKvj3QFqmM=";
    };
  };
  artifact =
    artifacts.${stdenv.hostPlatform.system}
      or (throw "TWG does not support ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "twg";
  inherit version;

  src = fetchurl {
    url = "https://teamwork-graph.atlassian.com/cli/twg-${artifact.platform}-v${version}";
    inherit (artifact) hash;
  };

  nativeBuildInputs = lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/twg"
    runHook postInstall
  '';

  # Preserve Atlassian's Developer ID signature on macOS.
  dontStrip = true;

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    "$out/bin/twg" --version | grep -Fx '${version}'
    runHook postInstallCheck
  '';

  meta = {
    description = "Atlassian Teamwork Graph command-line interface";
    homepage = "https://teamwork-graph.atlassian.com/cli/install";
    license = lib.licenses.unfree;
    mainProgram = "twg";
    platforms = lib.attrNames artifacts;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}

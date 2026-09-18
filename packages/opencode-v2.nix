{
  fetchurl,
  lib,
  stdenvNoCC,
  unzip,
}:
let
  version = "2.0.6";
  artifacts = {
    aarch64-darwin = {
      file = "opencode-darwin-arm64.zip";
      hash = "sha256-VlIVGKp/XKJQ0aNtx/hnTVUGZFqQJtSLAHaXuQIWITw=";
      format = "zip";
    };
    x86_64-darwin = {
      file = "opencode-darwin-x64.zip";
      hash = "sha256-tZ6hFNUYgGwF8TxQbt8kRsUw9ihaBU/Jr0hYFsSmPfc=";
      format = "zip";
    };
    aarch64-linux = {
      file = "opencode-linux-arm64.tar.gz";
      hash = "sha256-wHS+xv0FJWqqRFJamYZBhibgBFmUQ38w6Cs+zgkpGdg=";
      format = "tar";
    };
    x86_64-linux = {
      file = "opencode-linux-x64.tar.gz";
      hash = "sha256-gzADIT4VUmbAc64/GeKmPQJ7nWaovJpGEOycnUs2nI0=";
      format = "tar";
    };
  };
  artifact = artifacts.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "opencode";
  inherit version;

  src = fetchurl {
    url = "https://opencode.ai/files/bin/${version}/${artifact.file}";
    inherit (artifact) hash;
  };

  nativeBuildInputs = lib.optional (artifact.format == "zip") unzip;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    ${
      if artifact.format == "zip" then
        ''unzip -p "$src" opencode > "$out/bin/opencode"''
      else
        ''tar -xOzf "$src" opencode > "$out/bin/opencode"''
    }
    chmod 755 "$out/bin/opencode"
    runHook postInstall
  '';

  # Preserve upstream's Developer ID signature on macOS. Stripping the Bun
  # executable causes macOS 27 to kill it with SIGKILL before it reaches main.
  dontStrip = true;

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    export HOME="$TMPDIR/home"
    export XDG_CACHE_HOME="$HOME/.cache"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_DATA_HOME="$HOME/.local/share"
    export XDG_STATE_HOME="$HOME/.local/state"
    mkdir -p "$HOME"
    cd "$HOME"
    "$out/bin/opencode" --version | grep -F "opencode v${version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "Open source AI coding agent, V2 terminal client";
    homepage = "https://opencode.ai/v2/docs";
    license = lib.licenses.mit;
    mainProgram = "opencode";
    platforms = lib.attrNames artifacts;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}

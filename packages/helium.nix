{
  appimageTools,
  fetchurl,
  lib,
  stdenv,
}:
let
  pname = "helium";
  version = "0.18.1.1";
  platform =
    {
      aarch64-linux = {
        arch = "arm64";
        hash = "sha256-35KVUqsbpEhqAns2b+PtmzqQKRwiJ3ebRAQUdu7eytc=";
      };
      x86_64-linux = {
        arch = "x86_64";
        hash = "sha256-0eG5k9+/7gbp+Q6KKc1Y6HpHUZewT8BIdQYifDOFacs=";
      };
    }
    .${stdenv.hostPlatform.system} or (throw "Helium does not support ${stdenv.hostPlatform.system}");
  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-${platform.arch}.AppImage";
    inherit (platform) hash;
  };
  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/helium.desktop $out/share/applications/helium.desktop
    install -Dm444 ${appimageContents}/helium.png $out/share/pixmaps/helium.png
  '';

  meta = {
    description = "Private, fast, and honest Chromium-based web browser";
    homepage = "https://helium.computer/";
    license = lib.licenses.gpl3Only;
    mainProgram = "helium";
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}

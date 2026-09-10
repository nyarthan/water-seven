{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
}:
buildNpmPackage rec {
  pname = "tokentracker-cli";
  version = "0.96.2";

  src = fetchFromGitHub {
    owner = "xiufengsun";
    repo = "TokenTracker";
    rev = "v${version}";
    hash = "sha256-Y9qwTkk9pBpf0bjBw2suGyDbS4EJoHoZj8k9wF2cYSA=";
  };

  npmDepsHash = "sha256-m6EX3PZ8Cv5vGiI95Kp4YS1+4b6ebi8Sw5gkuRPxIEs=";

  # Upstream declares but does not import @mongodb-js/zstd. Its install script
  # downloads a prebuilt binary, so keep the otherwise pure-JavaScript CLI
  # offline by suppressing dependency rebuild scripts.
  npmRebuildFlags = [ "--ignore-scripts" ];
  dontNpmBuild = true;

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    export HOME="$TMPDIR"
    "$out/bin/tokentracker" --version | grep -F "${version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "Local-first AI coding token usage and cost tracker";
    homepage = "https://www.tokentracker.cc";
    license = lib.licenses.mit;
    mainProgram = "tokentracker";
  };
}

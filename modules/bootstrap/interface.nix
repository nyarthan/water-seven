{
  config,
  lib,
  withSystem,
  ...
}:
let
  bootstrapFor =
    pkgs: withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }: config.packages.bootstrap);
  deploymentReadyHosts = lib.attrNames (
    lib.filterAttrs (_: host: host.deploymentReady) config.waterSeven.hosts
  );
in
{
  perSystem =
    { pkgs, ... }:
    let
      bootstrap = pkgs.writeShellApplication {
        name = "bootstrap";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.git
          pkgs.gnugrep
          pkgs.nix
          pkgs.nixos-anywhere
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          pkgs.disko
          pkgs.openssh
          pkgs.util-linux
        ];
        text = ''
          WATER_SEVEN_DEPLOYMENT_READY_HOSTS=${lib.escapeShellArg (lib.concatStringsSep " " deploymentReadyHosts)}
          ${builtins.readFile ../../scripts/bootstrap.sh}
        '';
      };
      # Apple's signed SSH binary has Local Network permission on macOS;
      # ad-hoc-signed Nix store binaries are denied access to LAN hosts.
      sshRuntimeCheck =
        if pkgs.stdenv.isDarwin then
          "! grep -F '${lib.getBin pkgs.openssh}/bin' '${bootstrap}/bin/bootstrap' "
        else
          "grep -F '${lib.getBin pkgs.openssh}/bin' '${bootstrap}/bin/bootstrap' ";
      bootstrapSshRuntime = pkgs.runCommand "bootstrap-ssh-runtime" { } ''
        ${sshRuntimeCheck}
        touch "$out"
      '';
    in
    {
      apps.bootstrap = {
        type = "app";
        program = lib.getExe bootstrap;
        meta.description = "Guided, resumable Water Seven host convergence";
      };

      checks.bootstrap-ssh-runtime = bootstrapSshRuntime;
      packages.bootstrap = bootstrap;
    };

  flake.modules.nixos.shared-workstation = { pkgs, ... }: {
    environment.systemPackages = [ (bootstrapFor pkgs) ];
  };

  flake.modules.darwin.shared-workstation =
    { pkgs, ... }:
    {
      options.waterSeven.bootstrap.followUpSteps = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Interactive macOS follow-up steps reported after bootstrap.";
      };

      config.environment.systemPackages = [ (bootstrapFor pkgs) ];
    };
}

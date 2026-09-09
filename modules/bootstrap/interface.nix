{ lib, withSystem, ... }:
let
  bootstrapFor =
    pkgs: withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }: config.packages.bootstrap);
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
          pkgs.openssh
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          pkgs.disko
          pkgs.util-linux
        ];
        text = builtins.readFile ../../scripts/bootstrap.sh;
      };
    in
    {
      apps.bootstrap = {
        type = "app";
        program = lib.getExe bootstrap;
        meta.description = "Guided, resumable Water Seven host convergence";
      };

      packages.bootstrap = bootstrap;
    };

  flake.modules.nixos.shared-workstation = { pkgs, ... }: {
    environment.systemPackages = [ (bootstrapFor pkgs) ];
  };

  flake.modules.darwin.shared-workstation =
    { pkgs, ... }:
    {
      options.waterSeven.bootstrap.permissionSteps = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Interactive macOS permission steps reported after bootstrap.";
      };

      config.environment.systemPackages = [ (bootstrapFor pkgs) ];
    };
}

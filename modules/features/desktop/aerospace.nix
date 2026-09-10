{ inputs, lib, ... }:
{
  flake.modules.darwin.platform-darwin =
    { pkgs, ... }:
    let
      unstable = import inputs.nixpkgs-unstable {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfreePredicate = package: lib.getName package == "raycast";
      };
    in
    {
      waterSeven.bootstrap.permissionSteps = [
        "AeroSpace: launch it and approve Accessibility when macOS requests it."
        "Raycast: launch it and approve the permissions required by the features you enable."
      ];

      environment.systemPackages = [
        pkgs.aerospace
        unstable.raycast
      ];
    };
}

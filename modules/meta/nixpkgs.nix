{ lib, ... }:
let
  allowedUnfreePackages = [
    "google-chrome"
    "mos"
    "obsidian"
    "orbstack"
    "raycast"
    "slack"
  ];

  packagePolicy = {
    nixpkgs.config.allowUnfreePredicate =
      package: builtins.elem (lib.getName package) allowedUnfreePackages;
  };
in
{
  options.waterSeven.allowedUnfreePackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = allowedUnfreePackages;
    readOnly = true;
    description = "Explicit allowlist of unfree package names.";
  };

  config = {
    flake.modules.nixos.shared-workstation = packagePolicy;
    flake.modules.darwin.shared-workstation = packagePolicy;
  };
}

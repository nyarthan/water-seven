{
  config,
  inputs,
  lib,
  ...
}:
{
  perSystem =
    { pkgs, system, ... }:
    let
      hosts = lib.filterAttrs (_: host: host.system == system) config.waterSeven.hosts;
      source = lib.cleanSource ../..;

      # Stable statix currently fails its own build on macOS. Keep this
      # exception local instead of exposing an unstable package namespace.
      inherit (import inputs.nixpkgs-unstable { inherit system; }) statix;

      hostChecks = lib.mapAttrs' (
        name: host:
        lib.nameValuePair "host-${name}" (
          if host.platform == "nixos" then
            config.flake.nixosConfigurations.${name}.config.system.build.toplevel
          else
            config.flake.darwinConfigurations.${name}.system
        )
      ) hosts;

      fleetSchema =
        assert lib.assertMsg (
          lib.attrNames config.waterSeven.hosts == [
            "baratie"
            "mini-merry"
            "striker"
          ]
        ) "Water Seven's initial fleet must contain baratie, mini-merry, and striker";
        pkgs.runCommand "water-seven-fleet-schema" { } "touch $out";

      formatting =
        pkgs.runCommand "water-seven-formatting"
          {
            nativeBuildInputs = [ pkgs.nixfmt-tree ];
            inherit source;
          }
          ''
            cp -R "$source" work
            chmod -R u+w work
            cd work
            ${lib.getExe pkgs.nixfmt-tree} --tree-root . --walk filesystem --ci
            touch "$out"
          '';

      nixLint =
        pkgs.runCommand "water-seven-nix-lint"
          {
            nativeBuildInputs = [
              pkgs.deadnix
              statix
            ];
            inherit source;
          }
          ''
            deadnix --fail "$source"
            statix check "$source"
            touch "$out"
          '';
    in
    {
      checks = hostChecks // {
        fleet-schema = fleetSchema;
        inherit formatting;
        nix-lint = nixLint;
      };

      formatter = pkgs.nixfmt-tree;

      devShells.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.deadnix
          pkgs.nixfmt-tree
          statix
        ];
      };
    };
}

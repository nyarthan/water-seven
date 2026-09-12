{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.waterSeven = {
    username = mkOption {
      type = types.strMatching "[a-z_][a-z0-9_-]*";
      default = "jannis";
      readOnly = true;
      description = "The Unix account managed across Water Seven workstations.";
    };

    projectsDirectory = mkOption {
      type = types.str;
      default = "Projects";
      readOnly = true;
      description = "The project directory below the managed user's home.";
    };

    hosts = mkOption {
      default = { };
      description = "The finite set of hosts managed by Water Seven.";
      type = types.lazyAttrsOf (
        types.submodule (
          { name, ... }: {
            options = {
              name = mkOption {
                type = types.str;
                default = name;
                readOnly = true;
              };

              platform = mkOption {
                type = types.enum [
                  "nixos"
                  "darwin"
                ];
              };

              system = mkOption {
                type = types.enum [
                  "aarch64-darwin"
                  "aarch64-linux"
                  "x86_64-linux"
                ];
              };

              role = mkOption {
                type = types.enum [
                  "work"
                  "personal"
                  "egghead"
                ];
              };

              deploymentReady = mkOption {
                type = types.bool;
                description = "Whether guided bootstrap may activate or install this host.";
              };

              os = mkOption {
                type = types.deferredModule;
                description = "The fully composed NixOS or nix-darwin module.";
              };

              home = mkOption {
                type = types.deferredModule;
                description = "The fully composed integrated Home Manager module.";
              };
            };
          }
        )
      );
    };
  };
}

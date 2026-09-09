{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.waterSeven;

  nixosHosts = lib.filterAttrs (_: host: host.platform == "nixos") cfg.hosts;
  darwinHosts = lib.filterAttrs (_: host: host.platform == "darwin") cfg.hosts;

  platformMatchesSystem =
    host:
    if host.platform == "nixos" then
      lib.hasSuffix "-linux" host.system
    else
      lib.hasSuffix "-darwin" host.system;

  revision = inputs.self.rev or null;

  mkNixos =
    name: host:
    assert lib.assertMsg (platformMatchesSystem host)
      "Water Seven host ${name} has platform ${host.platform} but system ${host.system}";
    inputs.nixpkgs.lib.nixosSystem {
      modules = [
        inputs.home-manager.nixosModules.home-manager
        host.os
        {
          nixpkgs.hostPlatform = host.system;
          system.configurationRevision = revision;

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${cfg.username} = host.home;
          };
        }
      ];
    };

  mkDarwin =
    name: host:
    assert lib.assertMsg (platformMatchesSystem host)
      "Water Seven host ${name} has platform ${host.platform} but system ${host.system}";
    inputs.nix-darwin.lib.darwinSystem {
      modules = [
        inputs.home-manager.darwinModules.home-manager
        host.os
        {
          nixpkgs.hostPlatform = host.system;
          system.configurationRevision = revision;

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${cfg.username} = host.home;
          };
        }
      ];
    };
in
{
  flake = {
    nixosConfigurations = lib.mapAttrs mkNixos nixosHosts;
    darwinConfigurations = lib.mapAttrs mkDarwin darwinHosts;
  };
}

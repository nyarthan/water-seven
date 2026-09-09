{ config, ... }:
let
  modules = config.flake.modules;
in
{
  waterSeven.hosts.baratie = {
    platform = "darwin";
    system = "aarch64-darwin";
    role = "work";

    os.imports = [
      modules.darwin.shared-workstation
      modules.darwin.role-work
      modules.darwin.platform-darwin
      modules.darwin.host-baratie
    ];

    home.imports = [
      modules.homeManager.shared-workstation
      modules.homeManager.role-work
      modules.homeManager.platform-darwin
      modules.homeManager.host-baratie
    ];
  };

  flake.modules.darwin.host-baratie = {
    networking = {
      computerName = "baratie";
      hostName = "baratie";
      localHostName = "baratie";
    };

    system.stateVersion = 6;
  };

  flake.modules.homeManager.host-baratie = { };
}

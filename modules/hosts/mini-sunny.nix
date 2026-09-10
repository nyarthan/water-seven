{ config, ... }:
let
  modules = config.flake.modules;
in
{
  waterSeven.hosts.mini-sunny = {
    platform = "darwin";
    system = "aarch64-darwin";
    role = "egghead";
    deploymentReady = true;

    os.imports = [
      modules.darwin.shared-workstation
      modules.darwin.role-egghead
      modules.darwin.platform-darwin
      modules.darwin.host-mini-sunny
    ];

    home.imports = [
      modules.homeManager.shared-workstation
      modules.homeManager.role-egghead
      modules.homeManager.platform-darwin
      modules.homeManager.host-mini-sunny
    ];
  };

  flake.modules.darwin.host-mini-sunny = {
    networking = {
      computerName = "mini-sunny";
      hostName = "mini-sunny";
      localHostName = "mini-sunny";
    };

    system.stateVersion = 6;
  };

  flake.modules.homeManager.host-mini-sunny = { };
}

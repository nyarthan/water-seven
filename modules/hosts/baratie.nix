{ config, ... }:
let
  modules = config.flake.modules;
in
{
  waterSeven.hosts.baratie = {
    platform = "darwin";
    system = "aarch64-darwin";
    role = "personal";
    deploymentReady = true;

    os.imports = [
      modules.darwin.shared-workstation
      modules.darwin.role-personal
      modules.darwin.platform-darwin
      modules.darwin.host-baratie
    ];

    home.imports = [
      modules.homeManager.shared-workstation
      modules.homeManager.role-personal
      modules.homeManager.platform-darwin
      modules.homeManager.host-baratie
    ];
  };

  flake.modules.darwin.host-baratie = {
    nix = {
      linux-builder.enable = true;
      settings.trusted-users = [ "jannis" ];
    };

    security.pam.services.sudo_local = {
      reattach = true;
      touchIdAuth = true;
    };

    networking = {
      computerName = "baratie";
      hostName = "baratie";
      localHostName = "baratie";
    };

    system.stateVersion = 6;
  };

  flake.modules.homeManager.host-baratie = { };
}

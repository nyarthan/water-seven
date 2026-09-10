{ config, ... }:
let
  modules = config.flake.modules;
in
{
  waterSeven.hosts.striker = {
    platform = "nixos";
    system = "x86_64-linux";
    role = "private";
    deploymentReady = false;

    os.imports = [
      modules.nixos.shared-workstation
      modules.nixos.role-private
      modules.nixos.platform-nixos
      modules.nixos.host-striker
    ];

    home.imports = [
      modules.homeManager.shared-workstation
      modules.homeManager.role-private
      modules.homeManager.platform-nixos
      modules.homeManager.host-striker
    ];
  };

  # Hardware and Disko facts will be added from the physical notebook before
  # its first installation. The root filesystem and UEFI loader below establish
  # architecture-independent boot invariants without guessing a physical disk.
  flake.modules.nixos.host-striker = {
    networking.hostName = "striker";
    system.stateVersion = "26.05";

    boot.loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };

    fileSystems."/" = {
      device = "/dev/mapper/crypted";
      fsType = "ext4";
    };
  };

  flake.modules.homeManager.host-striker = { };
}

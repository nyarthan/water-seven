{ config, inputs, ... }:
let
  modules = config.flake.modules;
in
{
  waterSeven.hosts.mini-merry = {
    platform = "nixos";
    system = "aarch64-linux";
    role = "egghead";
    deploymentReady = true;

    os.imports = [
      modules.nixos.shared-workstation
      modules.nixos.role-egghead
      modules.nixos.platform-nixos
      modules.nixos.host-mini-merry
    ];

    home.imports = [
      modules.homeManager.shared-workstation
      modules.homeManager.role-egghead
      modules.homeManager.platform-nixos
      modules.homeManager.host-mini-merry
    ];
  };

  flake.modules.nixos.host-mini-merry = {
    imports = [ inputs.disko.nixosModules.disko ];

    networking.hostName = "mini-merry";
    system.stateVersion = "26.05";

    boot = {
      initrd.availableKernelModules = [
        "virtio_blk"
        "virtio_pci"
        "virtio_scsi"
        "virtio_gpu"
      ];
      kernelParams = [
        "console=tty0"
        "console=hvc0"
      ];
      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot.enable = true;
      };
    };

    disko.devices.disk.system = {
      type = "disk";
      device = "/dev/vda";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };

          encrypted = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted";
              passwordFile = "/tmp/water-seven-luks.key";
              settings.allowDiscards = true;
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };

    services.qemuGuest.enable = true;
  };

  flake.modules.homeManager.host-mini-merry = { };
}

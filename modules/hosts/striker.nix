{ config, inputs, ... }:
let
  modules = config.flake.modules;
in
{
  waterSeven.hosts.striker = {
    platform = "nixos";
    system = "x86_64-linux";
    role = "work";
    deploymentReady = true;

    os.imports = [
      modules.nixos.shared-workstation
      modules.nixos.role-work
      modules.nixos.platform-nixos
      modules.nixos.host-striker
    ];

    home.imports = [
      modules.homeManager.shared-workstation
      modules.homeManager.role-work
      modules.homeManager.platform-nixos
      modules.homeManager.host-striker
    ];
  };

  flake.modules.nixos.host-striker =
    { config, lib, ... }:
    {
      imports = [ inputs.disko.nixosModules.disko ];

      networking.hostName = "striker";
      system.stateVersion = "26.05";

      boot = {
        initrd.availableKernelModules = [
          "xhci_pci"
          "thunderbolt"
          "nvme"
          "uas"
          "sd_mod"
          "sdhci_pci"
        ];
        kernelModules = [ "kvm-intel" ];
        loader = {
          efi.canTouchEfiVariables = true;
          systemd-boot.enable = true;
        };
      };

      disko.devices.disk.system = {
        type = "disk";
        device = "/dev/nvme0n1";
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

      hardware = {
        bluetooth.enable = true;
        cpu.intel = {
          npu.enable = true;
          updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
        };
        enableRedistributableFirmware = true;
        nvidia = {
          modesetting.enable = true;
          open = true;
          powerManagement.enable = true;
          prime = {
            intelBusId = "PCI:0@0:2:0";
            nvidiaBusId = "PCI:2@0:0:0";
            offload = {
              enable = true;
              enableOffloadCmd = true;
            };
          };
        };
        tuxedo-drivers.enable = true;
      };

      services = {
        fstrim.enable = true;
        fwupd.enable = true;
        power-profiles-daemon.enable = true;
        thermald.enable = true;
        xserver.videoDrivers = [ "nvidia" ];
      };
    };

  flake.modules.homeManager.host-striker = { };
}

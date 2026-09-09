{ config, ... }:
let
  username = config.waterSeven.username;
in
{
  flake.modules.nixos.platform-nixos = {
    networking = {
      firewall.enable = true;
      networkmanager.enable = true;
    };

    services.openssh.enable = false;

    users = {
      # Passwords are independent bootstrap secrets and are set outside the
      # public configuration; declarative account identity remains authoritative.
      mutableUsers = true;
      users = {
        root.hashedPassword = "!";
        ${username}.extraGroups = [ "networkmanager" ];
      };
    };

    security.sudo.wheelNeedsPassword = true;
  };

  flake.modules.homeManager.platform-nixos = {
    home.homeDirectory = "/home/${username}";
    xdg.enable = true;
  };
}

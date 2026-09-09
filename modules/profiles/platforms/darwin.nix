{ config, ... }:
let
  username = config.waterSeven.username;
in
{
  flake.modules.darwin.platform-darwin = {
    nix.enable = true;
    system.primaryUser = username;
  };

  flake.modules.homeManager.platform-darwin = {
    home.homeDirectory = "/Users/${username}";
  };
}

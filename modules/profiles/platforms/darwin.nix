{
  config,
  inputs,
  lib,
  ...
}:
let
  username = config.waterSeven.username;
in
{
  flake.modules.darwin.platform-darwin = {
    imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

    nix.enable = true;

    nix-homebrew = {
      enable = true;
      enableRosetta = false;
      user = username;
      autoMigrate = true;
      mutableTaps = false;
    };

    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = false;
        cleanup = "uninstall";
        upgrade = false;
      };
    };

    system = {
      activationScripts.setup-homebrew.text = lib.mkBefore ''
        /bin/bash ${../../../scripts/prepare-darwin-homebrew-taps.sh} /opt/homebrew
      '';
      primaryUser = username;
    };
  };

  flake.modules.homeManager.platform-darwin = {
    home = {
      homeDirectory = "/Users/${username}";
      sessionVariables = {
        LANG = "en_US.UTF-8";
        LC_CTYPE = "en_US.UTF-8";
      };
    };
  };
}

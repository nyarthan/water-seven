{ config, ... }:
let
  username = config.waterSeven.username;
  projectsDirectory = config.waterSeven.projectsDirectory;
in
{
  flake.modules = {
    nixos.shared-workstation = { pkgs, ... }: {
      users.users.${username} = {
        isNormalUser = true;
        uid = 1000;
        description = "Jannis";
        shell = pkgs.bashInteractive;
        extraGroups = [ "wheel" ];
      };

      programs.bash.enable = true;
      environment.shells = [ pkgs.bashInteractive ];
    };

    darwin.shared-workstation = { pkgs, ... }: {
      users.users.${username} = {
        home = "/Users/${username}";
        shell = pkgs.bashInteractive;
      };

      programs.bash.enable = true;
      environment.shells = [ pkgs.bashInteractive ];

      # Setup Assistant owns the administrator account, so it must not be in
      # nix-darwin's knownUsers. Enforce only the declared login shell.
      system.activationScripts.postActivation.text = ''
        /usr/bin/dscl . -create /Users/${username} UserShell /run/current-system/sw/bin/bash
      '';
    };

    homeManager.shared-workstation = {
      home = {
        inherit username;
        stateVersion = "26.05";
        sessionVariables.XDG_PROJECTS_DIR = "$HOME/${projectsDirectory}";
      };

      programs.home-manager.enable = true;
    };
  };
}

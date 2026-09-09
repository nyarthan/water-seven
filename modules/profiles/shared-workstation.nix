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
    };

    homeManager.shared-workstation = { pkgs, ... }: {
      home = {
        inherit username;
        stateVersion = "26.05";
        sessionVariables.XDG_PROJECTS_DIR = "$HOME/${projectsDirectory}";
        packages = [ pkgs.git ];
      };

      programs.home-manager.enable = true;
    };
  };
}

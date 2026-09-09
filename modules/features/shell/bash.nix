{ config, ... }:
let
  projectsDirectory = config.waterSeven.projectsDirectory;
in
{
  flake.modules.homeManager.shared-workstation =
    { config, pkgs, ... }:
    let
      checkout = "${config.home.homeDirectory}/${projectsDirectory}/water-seven";
    in
    {
      home = {
        packages = with pkgs; [
          bat
          curl
          eza
          fd
          fzf
          jq
          less
          mise
          ripgrep
        ];
        sessionVariables = {
          BAT_THEME = "ansi";
          MANPAGER = "sh -c 'col -bx | bat -l man -p'";
          PAGER = "less";
        };
      };

      programs = {
        atuin = {
          enable = true;
          enableBashIntegration = false;
          settings = {
            auto_sync = false;
            update_check = false;
          };
        };
        bash = {
          enable = true;
          enableCompletion = true;
          initExtra = ''
            source "${checkout}/native/bash/bashrc"
          '';
        };
        direnv = {
          enable = true;
          enableBashIntegration = false;
          nix-direnv.enable = true;
        };
        starship = {
          enable = true;
          enableBashIntegration = false;
        };
        zoxide = {
          enable = true;
          enableBashIntegration = false;
        };
      };

      xdg.configFile."water-seven/generated/bash.sh".text = ''
        # Generated environment facts. Do not edit.
        export XDG_PROJECTS_DIR="${config.home.homeDirectory}/${projectsDirectory}"
      '';
    };
}

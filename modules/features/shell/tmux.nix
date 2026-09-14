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
      programs.tmux = {
        enable = true;
        extraConfig = ''
          source-file "${checkout}/native/tmux/tmux.conf"
        '';
      };

      xdg.configFile."water-seven/generated/tmux.conf".text = ''
        # Generated package paths. Do not edit.
        set-option -g default-shell '${pkgs.bashInteractive}/bin/bash'
        set-option -g default-command '${pkgs.bashInteractive}/bin/bash --login'
      '';
    };
}

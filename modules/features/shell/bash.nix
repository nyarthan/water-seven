{ config, inputs, ... }:
let
  projectsDirectory = config.waterSeven.projectsDirectory;
in
{
  flake.modules.homeManager.shared-workstation =
    { config, pkgs, ... }:
    let
      checkout = "${config.home.homeDirectory}/${projectsDirectory}/water-seven";
      unstable = import inputs.nixpkgs-unstable { inherit (pkgs.stdenv.hostPlatform) system; };
    in
    {
      home = {
        packages = with pkgs; [
          bat
          curl
          unstable.devenv
          eza
          fd
          fzf
          jq
          less
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
            enter_accept = true;
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
        mise = {
          enable = true;
          enableBashIntegration = false;
          package = unstable.mise;
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

      xdg.configFile = {
        "devenv/config.yaml".text = ''
          # yaml-language-server: $schema=https://devenv.sh/devenv.user.schema.json
          version: 1
          tui:
            viewport: top
        '';

        "mise/config.toml" = {
          force = true;
          text = ''
            # Global tools are intentionally empty. Project configuration owns
            # project toolchains and their exact versions.
            [tools]
          '';
        };

        "water-seven/generated/bash.sh".text = ''
          # Generated environment facts. Do not edit.
          export XDG_PROJECTS_DIR="${config.home.homeDirectory}/${projectsDirectory}"
        '';
      };
    };
}

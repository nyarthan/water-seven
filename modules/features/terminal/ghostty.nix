{ config, lib, ... }:
let
  projectsDirectory = config.waterSeven.projectsDirectory;

  tmuxCommandBindings = lib.concatStringsSep "\n" (
    [
      "keybind = cmd+h=esc:h"
      "keybind = cmd+j=esc:j"
      "keybind = cmd+k=esc:k"
      "keybind = cmd+l=esc:l"
    ]
    ++ map (number: "keybind = cmd+${toString number}=esc:${toString number}") (lib.range 1 9)
  );
in
{
  flake.modules = {
    nixos.platform-nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.ghostty ];
    };

    darwin.platform-darwin = {
      homebrew.casks = [ "ghostty" ];
    };

    homeManager = {
      shared-workstation =
        { config, ... }:
        let
          checkout = "${config.home.homeDirectory}/${projectsDirectory}/water-seven";
        in
        {
          xdg.configFile."ghostty/config".source =
            config.lib.file.mkOutOfStoreSymlink "${checkout}/native/ghostty/config";
        };

      platform-nixos =
        { config, ... }:
        let
          checkout = "${config.home.homeDirectory}/${projectsDirectory}/water-seven";
        in
        {
          xdg.configFile."water-seven/generated/ghostty.conf".text = ''
            # Generated Linux fragment. Do not edit.
            config-file = ${checkout}/native/ghostty/linux.conf
            keybind = ctrl+shift+t=unbind
            keybind = ctrl+shift+e=unbind
            keybind = ctrl+shift+o=unbind
          '';
        };

      platform-darwin =
        { config, ... }:
        let
          checkout = "${config.home.homeDirectory}/${projectsDirectory}/water-seven";
        in
        {
          xdg.configFile."water-seven/generated/ghostty.conf".text = ''
            # Generated macOS fragment and terminal-layer translation. Do not edit.
            config-file = ${checkout}/native/ghostty/darwin.conf
            keybind = cmd+t=unbind
            keybind = cmd+d=unbind
            keybind = cmd+shift+d=unbind
            ${tmuxCommandBindings}
          '';
        };
    };
  };
}

{ config, lib, ... }:
let
  desktop = config.waterSeven.ux.desktop;

  directionalCommands = {
    focus-left = "movefocus, l";
    focus-down = "movefocus, d";
    focus-up = "movefocus, u";
    focus-right = "movefocus, r";
    move-window-left = "movewindow, l";
    move-window-down = "movewindow, d";
    move-window-up = "movewindow, u";
    move-window-right = "movewindow, r";
  };

  workspaceCommands = builtins.listToAttrs (
    lib.concatMap (
      number:
      let
        workspace = toString number;
      in
      [
        {
          name = "select-workspace-${workspace}";
          value = "workspace, ${workspace}";
        }
        {
          name = "move-to-workspace-${workspace}";
          value = "movetoworkspace, ${workspace}";
        }
      ]
    ) (lib.range 1 9)
  );

  commands =
    directionalCommands
    // workspaceCommands
    // {
      toggle-floating = "togglefloating";
      toggle-maximize = "fullscreen, 1";
      open-launcher = "exec, fuzzel";
    };

  renderBinding =
    action: binding:
    let
      modifiers = "SUPER" + lib.optionalString binding.shift " SHIFT";
    in
    "bind = ${modifiers}, ${binding.key}, ${commands.${action}}";

  renderedBindings = lib.concatStringsSep "\n" (lib.mapAttrsToList renderBinding desktop.actions);
in
{
  waterSeven.ux.desktop.adapters.hyprland = commands;

  flake.modules.homeManager.platform-nixos = {
    xdg.configFile."water-seven/generated/hyprland-bindings.conf".text = ''
      # Generated from the Water Seven UX contract. Do not edit.
      ${renderedBindings}
    '';
  };
}

{ config, lib, ... }:
let
  desktop = config.waterSeven.ux.desktop;

  directionalCommands = {
    focus-left = ''hl.dsp.focus({ direction = "left" })'';
    focus-down = ''hl.dsp.focus({ direction = "down" })'';
    focus-up = ''hl.dsp.focus({ direction = "up" })'';
    focus-right = ''hl.dsp.focus({ direction = "right" })'';
    move-window-left = ''hl.dsp.window.move({ direction = "left" })'';
    move-window-down = ''hl.dsp.window.move({ direction = "down" })'';
    move-window-up = ''hl.dsp.window.move({ direction = "up" })'';
    move-window-right = ''hl.dsp.window.move({ direction = "right" })'';
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
          value = "hl.dsp.focus({ workspace = ${workspace} })";
        }
        {
          name = "move-to-workspace-${workspace}";
          value = "hl.dsp.window.move({ workspace = ${workspace} })";
        }
      ]
    ) (lib.range 1 9)
  );

  commands =
    directionalCommands
    // workspaceCommands
    // {
      toggle-floating = ''hl.dsp.window.float({ action = "toggle" })'';
      toggle-maximize = ''hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })'';
      open-launcher = ''hl.dsp.exec_cmd("fuzzel")'';
      open-terminal = ''hl.dsp.exec_cmd("ghostty")'';
      close-window = "hl.dsp.window.close()";
      lock-session = ''hl.dsp.exec_cmd("loginctl lock-session")'';
      logout-session = "hl.dsp.exit()";
    };

  renderBinding =
    action: binding:
    let
      modifiers = "SUPER" + lib.optionalString binding.shift " + SHIFT";
    in
    ''hl.bind("${modifiers} + ${binding.key}", ${commands.${action}})'';

  renderedBindings = lib.concatStringsSep "\n" (lib.mapAttrsToList renderBinding desktop.actions);
in
{
  waterSeven.ux.desktop.adapters.hyprland = commands;

  flake.modules.homeManager.platform-nixos = {
    xdg.configFile."hypr/water_seven/bindings.lua".text = ''
      -- Generated from the Water Seven UX contract. Do not edit.
      ${renderedBindings}
    '';
  };
}

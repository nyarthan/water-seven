{ config, lib, ... }:
let
  desktop = config.waterSeven.ux.desktop;

  directionalCommands = {
    focus-left = "focus left";
    focus-down = "focus down";
    focus-up = "focus up";
    focus-right = "focus right";
    move-window-left = "move left";
    move-window-down = "move down";
    move-window-up = "move up";
    move-window-right = "move right";
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
          value = "workspace ${workspace}";
        }
        {
          name = "move-to-workspace-${workspace}";
          value = "move-node-to-workspace ${workspace}; workspace ${workspace}";
        }
      ]
    ) (lib.range 1 9)
  );

  commands =
    directionalCommands
    // workspaceCommands
    // {
      toggle-floating = "layout floating tiling";
      toggle-maximize = "fullscreen";
      open-launcher = "exec-and-forget open -a Raycast";
      open-terminal = "exec-and-forget open -na Ghostty";
      close-window = "close";
      lock-session = "exec-and-forget pmset displaysleepnow";
      logout-session = "exec-and-forget osascript -e 'tell application \"System Events\" to log out'";
    };

  renderKey = binding: "alt-${lib.optionalString binding.shift "shift-"}${lib.toLower binding.key}";

  bindings = lib.mapAttrs' (
    action: binding: lib.nameValuePair (renderKey binding) commands.${action}
  ) desktop.actions;
in
{
  waterSeven.ux.desktop.adapters.aerospace = commands;

  flake.modules.homeManager.platform-darwin =
    { pkgs, ... }:
    let
      toml = pkgs.formats.toml { };
    in
    {
      home.file.".aerospace.toml".source = toml.generate "aerospace.toml" {
        config-version = 2;
        start-at-login = true;
        on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];
        mode.main.binding = bindings;
      };
    };
}

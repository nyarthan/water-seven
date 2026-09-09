{ lib, ... }:
let
  directions = {
    left = "H";
    down = "J";
    up = "K";
    right = "L";
  };

  directionalActions = lib.concatMapAttrs (direction: key: {
    "focus-${direction}" = { inherit key; };
    "move-window-${direction}" = {
      inherit key;
      shift = true;
    };
  }) directions;

  workspaceActions = builtins.listToAttrs (
    lib.concatMap (
      number:
      let
        key = toString number;
      in
      [
        {
          name = "select-workspace-${key}";
          value = { inherit key; };
        }
        {
          name = "move-to-workspace-${key}";
          value = {
            inherit key;
            shift = true;
          };
        }
      ]
    ) (lib.range 1 9)
  );
in
{
  waterSeven.ux.desktop.actions =
    directionalActions
    // workspaceActions
    // {
      toggle-floating = {
        key = "F";
      };
      toggle-maximize = {
        key = "F";
        shift = true;
      };
      open-launcher = {
        key = "SPACE";
      };
    };
}

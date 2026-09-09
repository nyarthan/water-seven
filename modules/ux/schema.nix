{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.waterSeven.ux.desktop = {
    actions = mkOption {
      default = { };
      description = "Shared desktop actions and their physical binding shape.";
      type = types.lazyAttrsOf (
        types.submodule {
          options = {
            key = mkOption {
              type = types.str;
            };

            shift = mkOption {
              type = types.bool;
              default = false;
            };

            support = mkOption {
              type = types.enum [
                "required"
                "preferred"
                "platform-native"
              ];
              default = "required";
            };
          };
        }
      );
    };

    adapters = mkOption {
      default = { };
      description = "Native command implementing each shared action per adapter.";
      type = types.lazyAttrsOf (types.lazyAttrsOf types.str);
    };
  };
}

{ inputs, ... }:
{
  flake.modules.homeManager.shared-workstation =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      unstable = import inputs.nixpkgs-unstable {
        inherit (pkgs.stdenv.hostPlatform) system;
      };
      pi = unstable.pi-coding-agent;
      piResources = pkgs.callPackage ../../../packages/pi-resources.nix { };
      settingsFormat = pkgs.formats.json { };
      settings = settingsFormat.generate "pi-settings.json" (
        builtins.fromJSON (builtins.readFile ../../../native/pi/settings.json)
        // {
          lastChangelogVersion = pi.version;
        }
      );
    in
    {
      home = {
        packages = [ pi ];

        file = {
          ".pi/agent/settings.json" = {
            source = settings;
            force = true;
          };
          ".pi/agent/keybindings.json" = {
            source = ../../../native/pi/keybindings.json;
            force = true;
          };
          ".pi/agent/extensions" = {
            source = "${piResources}/extensions";
            force = true;
          };
          ".pi/agent/node_modules" = {
            source = "${piResources}/node_modules";
            force = true;
          };
          ".pi/agent/themes" = {
            source = "${piResources}/themes";
            force = true;
          };
        };
      };

      home.activation.removeLegacyPiCheckout = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        rm -rf \
          ${lib.escapeShellArg "${config.home.homeDirectory}/.pi/agent/.git"} \
          ${lib.escapeShellArg "${config.home.homeDirectory}/.pi/agent/docs"}
        rm -f \
          ${lib.escapeShellArg "${config.home.homeDirectory}/.pi/agent/.gitignore"} \
          ${lib.escapeShellArg "${config.home.homeDirectory}/.pi/agent/.oxfmtrc.json"} \
          ${lib.escapeShellArg "${config.home.homeDirectory}/.pi/agent/CONTEXT.md"} \
          ${lib.escapeShellArg "${config.home.homeDirectory}/.pi/agent/mise.toml"} \
          ${lib.escapeShellArg "${config.home.homeDirectory}/.pi/agent/package.json"} \
          ${lib.escapeShellArg "${config.home.homeDirectory}/.pi/agent/pnpm-lock.yaml"} \
          ${lib.escapeShellArg "${config.home.homeDirectory}/.pi/agent/pnpm-workspace.yaml"} \
          ${lib.escapeShellArg "${config.home.homeDirectory}/.pi/agent/README.md"} \
          ${lib.escapeShellArg "${config.home.homeDirectory}/.pi/agent/TODO.md"} \
          ${lib.escapeShellArg "${config.home.homeDirectory}/.pi/agent/tsconfig.json"}
      '';
    };
}

{ inputs, ... }:
let
  githubMcp = {
    url = "https://api.githubcopilot.com/mcp/";
    headers.Authorization = "!printf 'Bearer '; gh auth token";
    description = "Search and manage GitHub repositories, issues, pull requests, and actions";
    exposure = "codemode";
  };
in
{
  flake.modules.homeManager = {
    shared-workstation =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        pi =
          (import inputs.pi-nixpkgs {
            inherit (pkgs.stdenv.hostPlatform) system;
          }).pi-coding-agent;
        piResources = pkgs.callPackage ../../../packages/pi-resources.nix { };
        jsonFormat = pkgs.formats.json { };
        settings = jsonFormat.generate "pi-settings.json" (
          builtins.fromJSON (builtins.readFile ../../../native/pi/settings.json)
          // {
            lastChangelogVersion = pi.version;
          }
        );
        mcp = jsonFormat.generate "pi-mcp.json" {
          mcpServers = config.waterSeven.pi.mcpServers;
        };
      in
      {
        options.waterSeven.pi.mcpServers = lib.mkOption {
          type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
          default = { };
          description = "Role-scoped MCP servers exposed through Pi.";
        };

        config = {
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
            }
            // lib.optionalAttrs (config.waterSeven.pi.mcpServers != { }) {
              ".pi/agent/mcp.json" = {
                source = mcp;
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
      };

    role-work.waterSeven.pi.mcpServers.github = githubMcp;

    role-personal.waterSeven.pi.mcpServers = {
      github = githubMcp;
      atlassian = {
        url = "https://mcp.atlassian.com/v2/mcp";
        description = "Search and manage Jira and Confluence through Atlassian OAuth";
        exposure = "codemode";
      };
      linear = {
        url = "https://mcp.linear.app/mcp";
        description = "Search and manage Linear issues, projects, and teams through OAuth";
        exposure = "codemode";
      };
    };
  };
}

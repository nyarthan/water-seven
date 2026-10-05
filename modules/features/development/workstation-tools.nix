{ inputs, lib, ... }:
{
  flake.modules = {
    darwin.role-work = {
      homebrew.brews = [ "mole" ];
    };

    homeManager = {
      role-work =
        { pkgs, ... }:
        let
          unstable = import inputs.nixpkgs-unstable {
            inherit (pkgs.stdenv.hostPlatform) system;
            config.allowUnfreePredicate =
              package:
              builtins.elem (lib.getName package) [
                "bws"
                "claude-code"
                "sonarqube-cli"
              ];
          };
          elastic-cli = pkgs.callPackage ../../../packages/elastic-cli.nix { };
          headroom-ai = unstable.callPackage ../../../packages/headroom-ai.nix { };
          tokentracker-cli = pkgs.callPackage ../../../packages/tokentracker-cli.nix { };
        in
        {
          home.packages =
            (with pkgs; [
              act
              awscli2
              bazel
              betterleaks
              cloudflared
              dust
              elastic-cli
              gh
              gitleaks
              gource
              headroom-ai
              hyperfine
              k9s
              lazygit
              tokentracker-cli
              trufflehog
              turbo
              typos
              uv
              yazi
              unstable.bws
              unstable.claude-code
              unstable.opencode
              unstable.rtk
              unstable.sonarqube-cli
              unstable.tuicr
              unstable.worktrunk
            ])
            ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.mole ];
        };

      role-personal =
        { config, pkgs, ... }:
        let
          unstable = import inputs.nixpkgs-unstable {
            inherit (pkgs.stdenv.hostPlatform) system;
            config.allowUnfreePredicate = package: lib.getName package == "sonarqube-cli";
          };
          twg = pkgs.callPackage ../../../packages/twg.nix { };
        in
        {
          home.packages = [
            pkgs.bazel
            pkgs.betterleaks
            pkgs.dust
            (pkgs.callPackage ../../../packages/elastic-cli.nix { })
            pkgs.gh
            pkgs.gitleaks
            pkgs.gource
            pkgs.k9s
            pkgs.lazygit
            unstable.sonarqube-cli
            pkgs.trufflehog
            pkgs.typos
            pkgs.uv
            (pkgs.callPackage ../../../packages/linearis.nix { })
            (pkgs.callPackage ../../../packages/opencode-v2.nix { })
            twg
          ];

          home.sessionPath = [ "$HOME/.local/share/uv/bin" ];

          home.sessionVariables = {
            DO_NOT_TRACK = "1";
            UV_TOOL_BIN_DIR = "$HOME/.local/share/uv/bin";
            TWG_BACKGROUND_UPDATE_CHECK = "0";
            TWG_COMMAND_SURFACE_RESTRICTION = "basic-v1";
            TWG_SKIP_BITBUCKET = "1";
          };

          launchd.agents.twg-upkeep = lib.mkIf pkgs.stdenv.isDarwin {
            enable = true;
            config = {
              Label = "com.atlassian.twg.upkeep";
              ProgramArguments = [
                "${twg}/bin/twg"
                "upkeep"
                "run"
                "--scheduled"
              ];
              EnvironmentVariables.TWG_CONFIG_DIR = "${config.home.homeDirectory}/.config/twg";
              ProcessType = "Background";
              RunAtLoad = true;
              StartInterval = 720;
            };
          };
        };
    };
  };
}

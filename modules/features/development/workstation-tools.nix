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
              ];
          };
          headroom-ai = unstable.callPackage ../../../packages/headroom-ai.nix { };
          tokentracker-cli = pkgs.callPackage ../../../packages/tokentracker-cli.nix { };
        in
        {
          home.packages = with pkgs; [
            act
            awscli2
            cloudflared
            devenv
            dust
            gh
            headroom-ai
            hyperfine
            lazygit
            tokentracker-cli
            turbo
            uv
            yazi
            unstable.bws
            unstable.claude-code
            unstable.opencode
            unstable.rtk
            unstable.tuicr
            unstable.worktrunk
          ];
        };

      role-private = { pkgs, ... }: {
        home.packages = [ (pkgs.callPackage ../../../packages/linearis.nix { }) ];
      };
    };
  };
}

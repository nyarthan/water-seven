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
          home.packages =
            (with pkgs; [
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
            ])
            ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.mole ];
        };

      role-personal =
        { pkgs, ... }:
        let
          twg = pkgs.writeShellApplication {
            name = "twg";
            text = ''
              twg_binary="$HOME/.local/share/mise/installs/twg/latest/twg"
              if [[ ! -x "$twg_binary" ]]; then
                echo "error: vendor-managed TWG is unavailable at $twg_binary" >&2
                exit 127
              fi
              exec "$twg_binary" "$@"
            '';
          };
        in
        {
          home.packages = [
            (pkgs.callPackage ../../../packages/linearis.nix { })
            twg
          ];
        };
    };
  };
}

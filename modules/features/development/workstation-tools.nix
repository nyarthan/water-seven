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
        { pkgs, ... }:
        let
          unstable = import inputs.nixpkgs-unstable {
            inherit (pkgs.stdenv.hostPlatform) system;
            config.allowUnfreePredicate = package: lib.getName package == "sonarqube-cli";
          };
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
            (pkgs.callPackage ../../../packages/linearis.nix { })
            (pkgs.callPackage ../../../packages/opencode-v2.nix { })
            twg
          ];
        };
    };
  };
}

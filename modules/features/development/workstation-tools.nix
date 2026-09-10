{ inputs, ... }:
{
  flake.modules.darwin.role-work = {
    homebrew.brews = [ "mole" ];
  };

  flake.modules.homeManager.role-work =
    { pkgs, ... }:
    let
      unstable = import inputs.nixpkgs-unstable {
        inherit (pkgs.stdenv.hostPlatform) system;
      };
    in
    {
      home.packages = with pkgs; [
        act
        awscli2
        cloudflared
        devenv
        dust
        gh
        hyperfine
        lazygit
        turbo
        uv
        yazi
        unstable.rtk
        unstable.tuicr
        unstable.worktrunk
      ];
    };
}

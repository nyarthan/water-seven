{ lib, ... }:
{
  flake.modules.homeManager.role-work = { pkgs, ... }: {
    home.packages =
      (with pkgs; [
        obsidian
        qbittorrent
      ])
      ++ lib.optionals pkgs.stdenv.isDarwin (
        with pkgs;
        [
          mos
          vlc-bin
        ]
      )
      ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.vlc ];
  };
}

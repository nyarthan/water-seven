{
  flake.modules.homeManager.role-work = { pkgs, ... }: {
    home.packages = with pkgs; [
      mos
      obsidian
      qbittorrent
      vlc-bin
    ];
  };
}

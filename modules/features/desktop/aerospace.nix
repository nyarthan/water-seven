{
  flake.modules.darwin.platform-darwin = {
    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = false;
        cleanup = "uninstall";
        upgrade = false;
      };
      taps = [ "nikitabobko/tap" ];
      casks = [
        "nikitabobko/tap/aerospace"
        "raycast"
      ];
    };
  };
}

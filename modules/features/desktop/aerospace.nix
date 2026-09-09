{
  flake.modules.darwin.platform-darwin = {
    waterSeven.bootstrap.permissionSteps = [
      "AeroSpace: launch it and approve Accessibility when macOS requests it."
      "Raycast: launch it and approve the permissions required by the features you enable."
    ];

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

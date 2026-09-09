{
  flake.modules.darwin.platform-darwin = { pkgs, ... }: {
    waterSeven.bootstrap.permissionSteps = [
      "AeroSpace: launch it and approve Accessibility when macOS requests it."
      "Raycast: launch it and approve the permissions required by the features you enable."
    ];

    environment.systemPackages = with pkgs; [
      aerospace
      raycast
    ];
  };
}

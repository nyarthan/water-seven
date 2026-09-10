{ inputs, lib, ... }:
{
  flake.modules.darwin.platform-darwin =
    { pkgs, ... }:
    let
      unstable = import inputs.nixpkgs-unstable {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfreePredicate = package: lib.getName package == "raycast";
      };
    in
    {
      waterSeven.bootstrap.followUpSteps = [
        "AeroSpace: launch it and approve Accessibility when macOS requests it."
        "Raycast: launch it and approve the permissions required by the features you enable."
      ];

      environment.systemPackages = [
        pkgs.aerospace
        unstable.raycast
      ];

      system.defaults.CustomUserPreferences."com.raycast.macos" = {
        emojiPicker_skinTone = "standard";
        navigationCommandStyleIdentifierKey = "vim";
        onboardingCompleted = true;
        raycastPreferredWindowMode = "compact";
        raycastShouldFollowSystemAppearance = 1;
        showGettingStartedLink = 0;
        useHyperKeyIcon = true;
      };
    };
}

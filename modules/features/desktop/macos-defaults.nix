{ config, ... }:
let
  username = config.waterSeven.username;
in
{
  flake.modules.darwin.platform-darwin = {
    system.defaults = {
      ActivityMonitor = {
        OpenMainWindow = true;
        ShowCategory = 100;
      };

      LaunchServices.LSQuarantine = true;

      NSGlobalDomain = {
        AppleEnableMouseSwipeNavigateWithScrolls = true;
        AppleEnableSwipeNavigateWithScrolls = true;
        AppleICUForce24HourTime = true;
        AppleInterfaceStyle = "Dark";
        AppleKeyboardUIMode = 2;
        AppleMeasurementUnits = "Centimeters";
        AppleMetricUnits = 1;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        AppleShowScrollBars = "Automatic";
        AppleTemperatureUnit = "Celsius";
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticInlinePredictionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSAutomaticWindowAnimationsEnabled = false;
        NSDocumentSaveNewDocumentsToCloud = false;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        NSUseAnimatedFocusRing = false;
        NSWindowShouldDragOnGesture = true;
        PMPrintingExpandedStateForPrint = true;
        PMPrintingExpandedStateForPrint2 = true;
        "com.apple.keyboard.fnState" = true;
        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.springing.enabled" = false;
        "com.apple.swipescrolldirection" = true;
      };

      WindowManager = {
        AutoHide = true;
        StandardHideWidgets = true;
      };

      controlcenter.BatteryShowPercentage = true;

      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.0;
        dashboard-in-overlay = true;
        expose-animation-duration = 0.0;
        launchanim = false;
        mru-spaces = false;
        orientation = "right";
        persistent-apps = [ ];
        persistent-others = [ ];
        show-process-indicators = false;
        show-recents = false;
        tilesize = 32;
        wvous-bl-corner = 1;
        wvous-br-corner = 1;
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
      };

      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        CreateDesktop = false;
        FXDefaultSearchScope = "SCcf";
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "Nlsv";
        NewWindowTarget = "Home";
        QuitMenuItem = true;
        ShowExternalHardDrivesOnDesktop = false;
        ShowPathbar = true;
        ShowRemovableMediaOnDesktop = false;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true;
        _FXSortFoldersFirst = true;
      };

      hitoolbox.AppleFnUsageType = "Do Nothing";
      loginwindow.GuestEnabled = false;
      screencapture.location = "~/Pictures/Screenshots";
      trackpad.Clicking = true;
    };

    system.activationScripts.postActivation.text = ''
      # Null nix-darwin defaults leave prior values untouched. Remove inherited
      # Tendril preferences whose desired state is the macOS default.
      user_id="$(/usr/bin/id -u -- ${username})"
      delete_global_default() {
        /bin/launchctl asuser "$user_id" \
          /usr/bin/sudo --user=${username} -- \
          /usr/bin/defaults delete -g "$1" >/dev/null 2>&1 || true
      }

      delete_global_default AppleFontSmoothing
      delete_global_default NSTableViewDefaultSizeMode
      delete_global_default NSDisableAutomaticTermination
      delete_global_default NSWindowResizeTime
      delete_global_default NSTextShowsControlCharacters
      delete_global_default com.apple.sound.beep.volume

      /usr/sbin/sysadminctl -autologin off >/dev/null 2>&1
    '';
  };
}

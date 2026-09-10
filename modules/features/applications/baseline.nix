{
  flake.modules = {
    nixos.shared-workstation = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        bitwarden-desktop
        brave
      ];
    };

    darwin.shared-workstation = { pkgs, ... }: {
      waterSeven.bootstrap.followUpSteps = [
        "Brave: confirm it is the default browser if macOS does not accept the declared handlers automatically."
      ];

      fonts.packages = [ pkgs.iosevka ];
      environment.systemPackages = with pkgs; [
        bitwarden-desktop
        brave
      ];

      system.defaults.CustomUserPreferences."com.apple.LaunchServices/com.apple.launchservices.secure" = {
        LSHandlers = map (handler: handler // { LSHandlerRoleAll = "com.brave.Browser"; }) [
          { LSHandlerContentType = "com.apple.default-app.web-browser"; }
          { LSHandlerContentType = "public.html"; }
          { LSHandlerURLScheme = "http"; }
          { LSHandlerURLScheme = "https"; }
        ];
      };
    };

    homeManager.shared-workstation = { pkgs, ... }: {
      home.packages = [ pkgs.bitwarden-cli ];
    };

    homeManager.platform-nixos = {
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "text/html" = [ "brave-browser.desktop" ];
          "x-scheme-handler/http" = [ "brave-browser.desktop" ];
          "x-scheme-handler/https" = [ "brave-browser.desktop" ];
        };
      };
    };

    nixos.role-private = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.google-chrome ];
    };
  };
}

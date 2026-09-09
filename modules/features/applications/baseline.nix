{
  flake.modules = {
    nixos.shared-workstation = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        bitwarden-desktop
        brave
      ];
    };

    darwin.shared-workstation = { pkgs, ... }: {
      fonts.packages = [ pkgs.iosevka ];
      environment.systemPackages = with pkgs; [
        bitwarden-desktop
        brave
      ];
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

{
  flake.modules = {
    nixos.shared-workstation = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.bitwarden-desktop ];
    };

    darwin.shared-workstation = { pkgs, ... }: {
      fonts.packages = [ pkgs.iosevka ];
      environment.systemPackages = [ pkgs.bitwarden-desktop ];
    };

    homeManager.shared-workstation = { pkgs, ... }: {
      home.packages = [ pkgs.bitwarden-cli ];
    };

    nixos.role-personal = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.google-chrome ];
    };

    darwin.role-personal = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.google-chrome ];
    };
  };
}

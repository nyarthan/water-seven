{ inputs, lib, ... }:
{
  flake.modules.darwin.role-personal =
    { pkgs, ... }:
    let
      unstable = import inputs.nixpkgs-unstable {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfreePredicate = package: lib.getName package == "whatsapp-for-mac";
      };
    in
    {
      environment.systemPackages = with pkgs; [
        orbstack
        proton-vpn
        scroll-reverser
        slack
        unstable.whatsapp-for-mac
      ];

      homebrew = {
        casks = [
          "affinity"
          "ausweisapp"
          "chatgpt"
          "helium-browser"
          "libreoffice"
          "microsoft-teams"
          "steam"
          "tableplus"
          "yubico-authenticator"
        ];

        masApps."P-touch Editor" = 1453365242;
      };

      waterSeven.bootstrap.followUpSteps = [
        "Logi Tune: retain the vendor-installed application and approve its required background items interactively; its Homebrew cask launches a manual installer."
        "Microsoft AutoUpdate: retain the vendor-managed installation required by Teams; its self-updated release may be newer than the Homebrew cask."
        "ScanSnap Home: retain the vendor-managed installation, device state, drivers, and required background items; its package cask cannot adopt an existing installation safely."
        "YubiKey Manager: retain the existing vendor application only; its presence does not authorize provisioning or changing a YubiKey."
        "Factorio and Hollow Knight: Silksong remain mutable Steam-managed games; verify both before removing any Steam library data."
        "ProtonVPN: verify and approve its Network Extension after migration if macOS requests consent."
      ];
    };
}

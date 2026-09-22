{ inputs, lib, ... }:
{
  flake.modules.darwin.role-personal =
    { pkgs, ... }:
    let
      unstable = import inputs.nixpkgs-unstable {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfreePredicate = package: lib.getName package == "whatsapp-for-mac";
      };
      slackAutoUpdateProfile =
        (pkgs.formats.plist { }).generate "slack-disable-auto-update.mobileconfig"
          {
            PayloadContent = [
              {
                AutoUpdate = false;
                PayloadDisplayName = "Slack update policy";
                PayloadIdentifier = "dev.water-seven.slack.disable-auto-update.preferences";
                PayloadType = "com.tinyspeck.slackmacgap";
                PayloadUUID = "96012630-011B-50C8-A059-2AB6B384E674";
                PayloadVersion = 1;
              }
            ];
            PayloadDescription = "Disable Slack's self-updater because Water Seven manages Slack through Nix.";
            PayloadDisplayName = "Water Seven: disable Slack self-updates";
            PayloadIdentifier = "dev.water-seven.slack.disable-auto-update";
            PayloadOrganization = "Water Seven";
            PayloadScope = "User";
            PayloadType = "Configuration";
            PayloadUUID = "763CDB7E-26D1-58ED-AA2A-D94D043B3357";
            PayloadVersion = 1;
          };
      verifySlackUpdatePolicy = pkgs.writeShellApplication {
        name = "verify-slack-update-policy";
        text = ''
          exec /usr/bin/osascript -l JavaScript <<'JXA'
          ObjC.import("Foundation")
          ObjC.import("CoreFoundation")

          const domain = "com.tinyspeck.slackmacgap"
          const key = "AutoUpdate"
          const defaults = $.NSUserDefaults.alloc.initWithSuiteName(domain)
          const forced = Boolean($.CFPreferencesAppValueIsForced($(key), $(domain)))
          const exists = ObjC.unwrap(defaults.objectForKey(key)) !== undefined
          const value = Boolean(defaults.boolForKey(key))

          console.log(`forced: ''${forced}`)
          console.log(`value: ''${exists ? value : "<unset>"}`)
          if (!forced || !exists || value) {
            throw new Error("Slack AutoUpdate must be a forced false preference")
          }
          JXA
        '';
      };
    in
    {
      environment = {
        systemPackages = with pkgs; [
          orbstack
          proton-vpn
          slack
          unstable.whatsapp-for-mac
          verifySlackUpdatePolicy
        ];

        etc."water-seven/profiles/slack-disable-auto-update.mobileconfig".source = slackAutoUpdateProfile;
      };

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
        "Slack: quit Slack, open /etc/water-seven/profiles/slack-disable-auto-update.mobileconfig, and approve the Water Seven profile in System Settings > General > Device Management. macOS requires this one-time consent; the profile enforces AutoUpdate=false because Nix owns Slack updates. Reopen Slack, then run verify-slack-update-policy."
        "Logi Tune: retain the vendor-installed application and approve its required background items interactively; its Homebrew cask launches a manual installer."
        "Microsoft AutoUpdate: retain the vendor-managed installation required by Teams; its self-updated release may be newer than the Homebrew cask."
        "ScanSnap Home: retain the vendor-managed installation, device state, drivers, and required background items; its package cask cannot adopt an existing installation safely."
        "YubiKey Manager: retain the existing vendor application only; its presence does not authorize provisioning or changing a YubiKey."
        "Factorio and Hollow Knight: Silksong remain mutable Steam-managed games; verify both before removing any Steam library data."
        "ProtonVPN: verify and approve its Network Extension after migration if macOS requests consent."
      ];
    };
}

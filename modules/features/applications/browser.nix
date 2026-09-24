{
  flake.modules =
    let
      # Leave the optional update URL unset. Helium routes the default Web Store
      # URL through its extension proxy; an explicit Google URL is treated as an
      # off-store source and blocked on machines without enterprise enrollment.
      extensionInstallForcelist = [
        # Bitwarden
        "nngceckbapebfimnlniiiahkandclblb"
        # Dark Reader
        "eimadpbcbfnmbkopoojfekhnkhdbieeh"
      ];
      recommendedPolicies = {
        DefaultBrowserSettingEnabled = true;
      };
    in
    {
      nixos.shared-workstation = { pkgs, ... }: {
        environment = {
          systemPackages = [ (pkgs.callPackage ../../../packages/helium.nix { }) ];
          etc = {
            "chromium/policies/managed/water-seven-extensions.json".text = builtins.toJSON {
              ExtensionInstallForcelist = extensionInstallForcelist;
            };
            "chromium/policies/recommended/water-seven-browser.json".text = builtins.toJSON recommendedPolicies;
          };
        };
      };

      darwin.shared-workstation =
        { pkgs, ... }:
        let
          extensionPolicyProfile = (pkgs.formats.plist { }).generate "helium-extension-policy.mobileconfig" {
            PayloadContent = [
              {
                ExtensionInstallForcelist = extensionInstallForcelist;
                PayloadDisplayName = "Helium extension policy";
                PayloadIdentifier = "dev.water-seven.helium.extensions.preferences";
                PayloadType = "net.imput.helium";
                PayloadUUID = "5D4E97FA-E7A5-57CC-8E23-159268E17B7C";
                PayloadVersion = 1;
              }
            ];
            PayloadDescription = "Force-install the browser extensions managed by Water Seven.";
            PayloadDisplayName = "Water Seven: Helium extensions";
            PayloadIdentifier = "dev.water-seven.helium.extensions";
            PayloadOrganization = "Water Seven";
            PayloadScope = "User";
            PayloadType = "Configuration";
            PayloadUUID = "C3FDAAEA-7BFD-58BB-9470-940030464560";
            PayloadVersion = 1;
          };
          verifyHeliumPolicy = pkgs.writeShellApplication {
            name = "verify-helium-policy";
            text = ''
              exec /usr/bin/osascript -l JavaScript <<'JXA'
              ObjC.import("Foundation")
              ObjC.import("CoreFoundation")

              const domain = "net.imput.helium"
              const key = "ExtensionInstallForcelist"
              const expected = ${builtins.toJSON extensionInstallForcelist}
              const defaults = $.NSUserDefaults.alloc.initWithSuiteName(domain)
              const forced = Boolean($.CFPreferencesAppValueIsForced($(key), $(domain)))
              const value = ObjC.deepUnwrap(defaults.arrayForKey(key))

              console.log(`forced: ''${forced}`)
              console.log(`value: ''${JSON.stringify(value)}`)
              if (!forced || JSON.stringify(value) !== JSON.stringify(expected)) {
                throw new Error("Helium must force-install the declared extensions")
              }
              JXA
            '';
          };
        in
        {
          environment = {
            systemPackages = [ verifyHeliumPolicy ];
            etc."water-seven/profiles/helium-extension-policy.mobileconfig".source = extensionPolicyProfile;
          };

          homebrew.casks = [ "helium-browser" ];

          system.defaults.CustomUserPreferences."net.imput.helium" = recommendedPolicies;

          waterSeven.bootstrap.followUpSteps = [
            "Helium: open it, choose 'Set as default browser', and approve the macOS prompt; this consent cannot be applied through defaults."
            "Helium extensions: quit Helium, open /etc/water-seven/profiles/helium-extension-policy.mobileconfig, and approve the Water Seven profile in System Settings > General > Device Management. Reopen Helium, enable Helium services for proxied extension downloads when prompted, then run verify-helium-policy."
          ];
        };

      homeManager.platform-nixos = {
        xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            "text/html" = [ "helium.desktop" ];
            "x-scheme-handler/http" = [ "helium.desktop" ];
            "x-scheme-handler/https" = [ "helium.desktop" ];
          };
        };
      };

      homeManager.host-baratie =
        { pkgs, ... }:
        let
          heliumExecutable = "/Applications/Helium.app/Contents/MacOS/Helium";
          mkProfileLauncher =
            name: profileDirectory:
            pkgs.writeShellApplication {
              inherit name;
              text = ''
                if [[ "''${1:-}" == "--help" || "''${1:-}" == "-h" ]]; then
                  echo "Usage: ${name} [URL ...]"
                  echo "Open Helium's ${profileDirectory} profile."
                  exit 0
                fi

                profile_path="$HOME/Library/Application Support/net.imput.helium/${profileDirectory}"
                if [[ ! -d "$profile_path" ]]; then
                  echo "error: Helium profile directory does not exist: $profile_path" >&2
                  exit 1
                fi
                if [[ ! -x "${heliumExecutable}" ]]; then
                  echo "error: Helium executable does not exist: ${heliumExecutable}" >&2
                  exit 1
                fi

                exec "${heliumExecutable}" --profile-directory="${profileDirectory}" "$@"
              '';
            };
          heliumPrimary = mkProfileLauncher "helium-primary" "Default";
          heliumSecondary = mkProfileLauncher "helium-secondary" "Profile 2";
          verifyHeliumProfiles = pkgs.writeShellApplication {
            name = "verify-helium-profiles";
            text = ''
              user_data_dir="$HOME/Library/Application Support/net.imput.helium"
              missing=0

              for profile in "Default" "Profile 2"; do
                if [[ -d "$user_data_dir/$profile" ]]; then
                  printf 'present: %s\n' "$profile"
                else
                  printf 'missing: %s\n' "$profile" >&2
                  missing=1
                fi
              done

              if [[ ! -x "${heliumExecutable}" ]]; then
                echo "missing: ${heliumExecutable}" >&2
                missing=1
              fi

              exit "$missing"
            '';
          };
        in
        {
          home.packages = [
            heliumPrimary
            heliumSecondary
            verifyHeliumProfiles
          ];
        };
    };
}

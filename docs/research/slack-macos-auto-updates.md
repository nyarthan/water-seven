# Slack for macOS auto-updates under Nix

**Status:** researched on 2026-09-16 on `baratie` (macOS 27.0, build 26A428). This note describes Slack 4.49.89, the version pinned by Water Seven at that date. Re-check the bundled code whenever Slack changes its updater.

## Conclusion

Yes. For Slack's direct-download macOS build in September 2026, the supported mechanism visible in the shipped application is a **forced managed preference** named `AutoUpdate`, with Boolean value `false`, in the `com.tinyspeck.slackmacgap` preference domain. It disables update support before Slack starts its hourly update timer, removes the in-app update command, and therefore prevents both the download and the recurring installer authorization prompt.

```text
preference domain: com.tinyspeck.slackmacgap
key:               AutoUpdate
value/type:        false / Boolean
requirement:       managed (“forced”), not an ordinary defaults value
```

`defaults write com.tinyspeck.slackmacgap SlackNoAutoUpdates -bool true` **does not work in Slack 4.49.89**. Neither `SlackNoAutoUpdates` nor `NoAutoUpdates` occurs in the executable, frameworks, or extracted `app.asar`; the current code instead declares the `AutoUpdate` external policy and checks it only when `CFPreferencesAppValueIsForced` says it is managed. Thus the starting article's historical command is not a current solution.[^starting-point]

Do not make Slack or `/Applications/Nix Apps` writable and do not approve the installer prompt. A self-update would compete with Nix's ownership and, if it succeeded, create mutable application state outside the selected Nix generation. Disable Slack's updater with a profile and update Slack by updating the pinned Nix package.

## What is producing the popups?

There are two related dialogs, followed by an updater error:

1. **Slack's own explanatory dialog.** When an update is available and the app bundle or its parent is not writable, Slack shows “Keep Slack up to date” and says that Slack will ask for permission and an administrator account will be needed. Its “Don't show me again” checkbox controls the internal `suppressPermissionDialog` setting. That setting is persisted with Slack's Redux state under `~/Library/Application Support/Slack/storage`; it only hides this explanatory dialog. It neither disables checks nor suppresses the subsequent macOS authorization request.
2. **The macOS administrator authorization dialog.** Electron's macOS `autoUpdater` uses Squirrel.Mac.[^electron-auto-updater] Squirrel tests whether both the resolved target app and its parent are writable. If either is not, it requests `kSMRightModifySystemDaemons` with `AuthorizationCreate`, submits `com.tinyspeck.slackmacgap.ShipIt` in the system launchd domain, and supplies the prompt text “An update is ready to install.”[^squirrel-launcher][^squirrel-updater] The short-lived, Slack-signed `ShipIt` executable is inside `Squirrel.framework`; it is not a separately installed login item.
3. **Cancellation and retry.** Current Squirrel deliberately memoizes a successful ShipIt submission but not an authorization cancellation or transient submission error, so it retries on a later subscription.[^squirrel-updater] Slack checks once when its environment becomes ready and then every hour while update support remains enabled. This explains recurrence; no persistent background helper is necessary.

This is an **in-process Slack/Electron update mechanism**, not App Store updating, `softwareupdated`, a Background Items login helper, or a permanently installed LaunchAgent. Local inspection found no Slack LaunchAgent and no registered `*.ShipIt` job after the failed attempt. It did find:

- `Slack.app/Contents/Frameworks/Squirrel.framework` and its signed `Resources/ShipIt`;
- `~/Library/Caches/com.tinyspeck.slackmacgap.ShipIt/ShipItState.plist`, targeting `/Applications/Nix Apps/Slack.app` and a downloaded replacement in the ShipIt cache;
- an update check for 4.52.155, an `update-available` event, and then `NSOSStatusErrorDomain` error `-60006` after the authorization UI;
- no Slack-specific managed preference at the time, and `SET_UPDATE_SUPPORTED true` in the log.

Slack's public deployment guidance is consistent with the permission diagnosis: a user needs write access to `/Applications`, `Slack.app`, and everything below it to self-update a DMG installation there.[^slack-deploy] That guidance is for conventionally mutable deployments; it should not be applied to a Nix-owned bundle.

## Current keys and policy behavior

### `AutoUpdate` — the actual control

The extracted 4.49.89 `main.bundle.cjs` declares a Boolean settings-policy descriptor whose internal and external names are both `AutoUpdate`. On macOS its policy backend does this in substance:

```js
isPreferenceForced("AutoUpdate")
getPreferenceValue("AutoUpdate")
```

The bundled `cf-prefs` 2.0.1 native module implements those operations with `CFPreferencesAppValueIsForced` and `CFPreferencesCopyAppValue`.[^cf-prefs] Slack's update-support calculation adds `updates disabled via external config` when the forced policy exists and is false. With update support false, the automatic update timer returns without checking and the update menu is omitted.

This distinction is essential:

```sh
# Ordinary user preference: NOT sufficient for Slack 4.49.89
/usr/bin/defaults write com.tinyspeck.slackmacgap AutoUpdate -bool false
```

`defaults` changes user defaults, but it does not make the key managed/forced. Apple's API explicitly distinguishes a value forced by an administrator from an ordinary application value.[^apple-forced] Consequently, nix-darwin's `system.defaults.CustomUserPreferences` is also insufficient: its implementation runs `defaults write` as the primary user.[^nix-darwin-defaults]

Slack also accepts policies nested under a forced `Defaults` dictionary, but forcing the single top-level `AutoUpdate` key is narrower and easier to verify.

### Other observed keys

| Key/setting | Effect | Recommendation |
|---|---|---|
| `SlackNoAutoUpdates` | No references in Slack 4.49.89 or its bundled Squirrel framework. | Do not use. The historical `defaults write` recipe is obsolete. |
| `AutoUpdate` | Forced Boolean policy; `false` disables update support. | Use in a configuration profile. |
| `suppressPermissionDialog` | Slack-internal persisted setting; suppresses only Slack's preparatory explanation. | Do not use as the fix. |
| `SquirrelMacEnableDirectContentsWrite` | Squirrel preference. If true, Squirrel ignores parent-directory writability, but still requires the target bundle itself to be writable. Slack may set/remove it around direct-content behavior. | Do not set. It does not disable updates and cannot make a Nix app writable. |
| `DISABLE_UPDATE_CHECK` | Environment variable recognized generically, but Slack's current `MacUpdater` constructor explicitly deletes it. | Not a viable launcher workaround. |

## Why Nix ownership triggers this

Water Seven installs `pkgs.slack` in `environment.systemPackages`. The pinned nixpkgs recipe downloads Slack's official arm64 DMG and copies the signed `Slack.app` unchanged into a Nix output.[^nixpkgs-slack] nix-darwin exposes that app under `/Applications/Nix Apps`.

On the inspected machine, `/Applications/Nix Apps` and `Slack.app` were root-owned and mode `0555`; the executable resolved to `/Applications/Nix Apps/Slack.app/Contents/MacOS/Slack`. Slack 4.49.89 was signed by `Developer ID Application: SLACK TECHNOLOGIES L.L.C. (BQR82RBBHL)`, and its bundled Squirrel and ShipIt were signed by the same team. The relevant `app.asar` SHA-256 was `c94e176f03a4e56a8cb2b6239ee887da60ff7488030e1b671525d690e8c0438e`.

This has two consequences:

- Squirrel correctly sees its target and parent as non-writable, selects its privileged path, and asks macOS for administrator authorization.
- Even administrator authorization must not be treated as permission to mutate Nix state. The app is generated from the Nix store/system generation. `chown`, `chmod`, copying a mutable replacement over it, or allowing ShipIt to replace it breaks ownership and rollback assumptions. A later rebuild would replace any mutation anyway.

The pinned package was 4.49.89 while Slack's service offered 4.52.155 during inspection. Once self-update is disabled, Water Seven assumes responsibility for prompt nixpkgs/Slack updates. Slack documents security guidance in desktop release notes and recommends prioritizing relevant releases.[^slack-update]

## Safe Water Seven design

Do **not** put this under `system.defaults.CustomUserPreferences`. Generate a small, stable configuration profile from Nix, but keep installation as an explicit native consent/deployment step. Apple defines configuration profiles as the mechanism for delivering settings, including settings for a single user or the whole device.[^apple-profiles] Since macOS 11, the `profiles` command cannot install configuration profiles; installation must be through System Settings or MDM.[^profiles-man]

A candidate custom-settings profile payload is:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>PayloadType</key><string>Configuration</string>
  <key>PayloadVersion</key><integer>1</integer>
  <key>PayloadIdentifier</key><string>dev.water-seven.slack-updates</string>
  <key>PayloadUUID</key><string>REPLACE-WITH-STABLE-PROFILE-UUID</string>
  <key>PayloadDisplayName</key><string>Water Seven: disable Slack self-update</string>
  <key>PayloadOrganization</key><string>Water Seven</string>
  <key>PayloadRemovalDisallowed</key><false/>
  <key>PayloadContent</key>
  <array>
    <dict>
      <key>PayloadType</key><string>com.tinyspeck.slackmacgap</string>
      <key>PayloadVersion</key><integer>1</integer>
      <key>PayloadIdentifier</key><string>dev.water-seven.slack-updates.preference</string>
      <key>PayloadUUID</key><string>REPLACE-WITH-STABLE-PAYLOAD-UUID</string>
      <key>PayloadDisplayName</key><string>Slack update policy</string>
      <key>AutoUpdate</key><false/>
    </dict>
  </array>
</dict>
</plist>
```

Apple's Custom settings payload is specifically for settings not exposed by another payload and uses the app's preference domain.[^apple-custom-settings] Before rollout, validate this exact profile on `mini-sunny`, because arbitrary third-party policy keys are Slack implementation details, not a promise in Slack's deployment documentation.

Recommended implementation shape (not implemented by this research):

1. Add a dedicated Darwin feature that uses `pkgs.writeText` to produce the `.mobileconfig` with fixed UUIDs. Do not include secrets, host identifiers, or a removal password.
2. Expose a bootstrap follow-up step that opens the generated profile and tells the user to approve it in **System Settings → General → Device Management**. Do not script writes into `/Library/Managed Preferences`; those are cfprefsd/profile-owned implementation files.
3. Add a native validator that checks `CFPreferencesAppValueIsForced("AutoUpdate", "com.tinyspeck.slackmacgap") == true` and that the copied value is Boolean false. A plain `defaults read` is not sufficient because it cannot prove forced status.
4. Assert at evaluation time that `slack` is present only where this policy is selected, and document that package updates now come only from the Water Seven rebuild cadence.
5. Keep profile installation as explicit mutable platform state unless an approved MDM becomes available. Nix can own the profile artifact and verification, but macOS owns installed-profile state and user consent.

Do not also set `SlackNoAutoUpdates`, alter Slack's ASAR, delete Squirrel from the signed bundle, block Slack's update hosts globally, or continuously kill ShipIt. Those approaches are ineffective, invalidate the upstream signature, interfere with normal Slack traffic, or race the updater instead of disabling it.

## Verification

Perform the profile install while Slack is fully quit; Apple's `defaults` documentation warns that running applications may cache or overwrite defaults.[^defaults-man]

1. Confirm the profile is installed:

   ```sh
   /usr/bin/profiles show -type configuration
   ```

   The output should include `dev.water-seven.slack-updates`.

2. Verify both value and forced status as the login user:

   ```sh
   cat >/tmp/check-slack-policy.swift <<'SWIFT'
   import CoreFoundation
   let app = "com.tinyspeck.slackmacgap" as CFString
   let key = "AutoUpdate" as CFString
   print("forced:", CFPreferencesAppValueIsForced(key, app))
   print("value:", CFPreferencesCopyAppValue(key, app) as Any)
   SWIFT
   /usr/bin/swift /tmp/check-slack-policy.swift
   rm /tmp/check-slack-policy.swift
   ```

   Expected: `forced: true` and a Boolean false value.

3. Start Slack. In `~/Library/Application Support/Slack/logs/default/browser.log`, expect `getIsUpdateSupported: Updates are not supported` with reason `updates disabled via external config`. The app should not log `autoUpdateTimerAppEpic` checks or request `/desktop/update/...`; **Slack → Check for Updates** should be absent.
4. Leave Slack running beyond one hour and relaunch it once. Neither the explanatory dialog nor the macOS authorization dialog should recur. `launchctl print gui/$(id -u)/com.tinyspeck.slackmacgap.ShipIt` should report no service. A stale ShipIt cache/state file may remain and is not evidence of an active helper.
5. Rebuild after a deliberate Slack package update and verify the same checks against the new ASAR. At minimum search the extracted bundle for `name:"AutoUpdate"`, `CFPreferencesAppValueIsForced`/`isPreferenceForced`, and `updates disabled via external config`; fail closed for manual review if those disappear.

## Rollback

1. Quit Slack.
2. Remove the profile in **System Settings → General → Device Management**. It is intentionally removable. The `profiles` tool can also remove an installed configuration profile by identifier, but use the UI for an unmanaged personal Mac so removal is explicit.[^profiles-man]
3. Verify `CFPreferencesAppValueIsForced` now prints `false`; no ordinary `AutoUpdate` value is required. If an earlier experiment wrote one, delete it only while Slack is quit:

   ```sh
   /usr/bin/defaults delete com.tinyspeck.slackmacgap AutoUpdate
   ```

4. Relaunch Slack and confirm `SET_UPDATE_SUPPORTED true` and the update command return. The next offered update may recreate/use `~/Library/Caches/com.tinyspeck.slackmacgap.ShipIt` and ask for authorization because the Nix app remains non-writable.
5. Prefer restoring the prior Git revision and matching nix-darwin generation for the declarative artifact/validator. Profile removal remains a separate native rollback action; Nix rollback alone cannot undo an installed profile.

Rollback should normally mean **remove the policy and let Nix install a reviewed Slack version**, not approve ShipIt to modify `/Applications/Nix Apps`.

## Sources

[^starting-point]: Rick Heil, [“Disabling auto-updates on Slack for Mac”](https://rickheil.com/disabling-auto-updates-on-slack-for-mac/). This was the starting hypothesis only; it is not treated as authoritative evidence.
[^slack-deploy]: Slack, [Deploy Slack for macOS](https://slack.com/help/articles/360035635174-Deploy-Slack-for-macOS) (especially the write-access troubleshooting section).
[^slack-update]: Slack, [Update the Slack desktop app](https://slack.com/help/articles/360048367814-Update-the-Slack-desktop-app).
[^electron-auto-updater]: Electron, [`autoUpdater` API, macOS platform notice](https://www.electronjs.org/docs/latest/api/auto-updater#macos).
[^squirrel-launcher]: Squirrel.Mac, [`SQRLShipItLauncher.m` at `61e8d079`](https://github.com/Squirrel/Squirrel.Mac/blob/61e8d0797029088a28703cbc1397d07a310c68a0/Squirrel/SQRLShipItLauncher.m#L79-L178).
[^squirrel-updater]: Squirrel.Mac, [`SQRLUpdater.m` privilege decision and retry behavior at `61e8d079`](https://github.com/Squirrel/Squirrel.Mac/blob/61e8d0797029088a28703cbc1397d07a310c68a0/Squirrel/SQRLUpdater.m#L400-L440); see also the upstream [configuration and install flow](https://github.com/Squirrel/Squirrel.Mac/blob/61e8d0797029088a28703cbc1397d07a310c68a0/README.md#configuration). The bundled binary exposes the corresponding selectors and behavior; current upstream source is corroborating source, not a claim that Slack published its exact Squirrel source revision.
[^cf-prefs]: `cf-prefs`, [`preferences.mm` at `497614c3`](https://github.com/MarshallOfSound/cf-prefs/blob/497614c3a79102ba18fc079f27b9df8751185060/preferences.mm#L165-L207) and [README](https://github.com/MarshallOfSound/cf-prefs/blob/497614c3a79102ba18fc079f27b9df8751185060/README.md). Slack 4.49.89 bundles version 2.0.1.
[^apple-forced]: Apple, [`CFPreferencesAppValueIsForced`](https://developer.apple.com/documentation/corefoundation/1515521-cfpreferencesappvalueisforced).
[^apple-profiles]: Apple Platform Deployment, [Intro to device management profiles](https://support.apple.com/guide/deployment/intro-to-device-management-profiles-depc0aadd3fe/web).
[^apple-custom-settings]: Apple Platform Deployment, [Custom settings payload settings](https://support.apple.com/guide/deployment/custom-payload-settings-dep4f529db9/web).
[^profiles-man]: Apple/macOS, the Apple-supplied `profiles(1)` manual installed with macOS 27. It states that, starting with macOS 11, `profiles` cannot install configuration profiles and directs users to System Settings.
[^defaults-man]: Apple/macOS, the Apple-supplied `defaults(1)` manual installed with macOS 27.
[^nixpkgs-slack]: Pinned nixpkgs, [`pkgs/by-name/sl/slack/package.nix` at `5dfba623`](https://github.com/NixOS/nixpkgs/blob/5dfba6236110080a54247d6460bc2ff5dda939cc/pkgs/by-name/sl/slack/package.nix) and [`darwin.nix`](https://github.com/NixOS/nixpkgs/blob/5dfba6236110080a54247d6460bc2ff5dda939cc/pkgs/by-name/sl/slack/darwin.nix).
[^nix-darwin-defaults]: Pinned nix-darwin, [`CustomPreferences.nix` and `defaults-write.nix` at `c3e90c89`](https://github.com/nix-darwin/nix-darwin/blob/c3e90c89649b07d1a96e4b9dd6cd0d6e44b91a74/modules/system/defaults-write.nix#L10-L18).

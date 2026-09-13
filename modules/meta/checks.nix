{
  config,
  inputs,
  lib,
  ...
}:
{
  perSystem =
    { pkgs, system, ... }:
    let
      hosts = lib.filterAttrs (_: host: host.system == system) config.waterSeven.hosts;
      representativeHostName = lib.head (lib.attrNames hosts);
      representativeHost = hosts.${representativeHostName};
      representativeSystem =
        if representativeHost.platform == "nixos" then
          config.flake.nixosConfigurations.${representativeHostName}
        else
          config.flake.darwinConfigurations.${representativeHostName};
      home = representativeSystem.config.home-manager.users.${config.waterSeven.username};
      darwinSystemPackages = representativeSystem.config.environment.systemPackages;
      darwinPackageNames = map (package: package.pname or (lib.getName package)) darwinSystemPackages;
      browserHandlers = lib.attrByPath [
        "system"
        "defaults"
        "CustomUserPreferences"
        "com.apple.LaunchServices/com.apple.launchservices.secure"
        "LSHandlers"
      ] null representativeSystem.config;
      darwinBrewNames = map (brew: brew.name) representativeSystem.config.homebrew.brews;
      darwinCasks = representativeSystem.config.homebrew.casks;
      darwinCaskNames = map (cask: cask.name) darwinCasks;
      darwinMasApps = representativeSystem.config.homebrew.masApps;
      personalCaskNames = [
        "affinity"
        "ausweisapp"
        "chatgpt"
        "fujitsu-scansnap-home"
        "helium-browser"
        "libreoffice"
        "microsoft-auto-update"
        "microsoft-teams"
        "steam"
        "tableplus"
        "yubico-authenticator"
      ];
      expectedDarwinCaskNames = [
        "ghostty"
      ]
      ++ lib.optionals (representativeHost.role == "personal") personalCaskNames;
      personalDarwinPackageNames = [
        "google-chrome"
        "orbstack"
        "proton-vpn"
        "scroll-reverser"
        "slack"
        "whatsapp-for-mac"
      ];
      deploymentReadyHostNames = lib.attrNames (
        lib.filterAttrs (_: host: host.deploymentReady) config.waterSeven.hosts
      );
      source = lib.cleanSource ../..;

      # Stable statix currently fails its own build on macOS. Keep this
      # exception local instead of exposing an unstable package namespace.
      inherit (import inputs.nixpkgs-unstable { inherit system; }) statix;

      hostChecks = lib.mapAttrs' (
        name: host:
        lib.nameValuePair "host-${name}" (
          if host.platform == "nixos" then
            config.flake.nixosConfigurations.${name}.config.system.build.toplevel
          else
            config.flake.darwinConfigurations.${name}.system
        )
      ) hosts;

      fleetSchema =
        assert lib.assertMsg (
          lib.attrNames config.waterSeven.hosts == [
            "baratie"
            "mini-merry"
            "mini-sunny"
            "striker"
          ]
        ) "Water Seven's fleet must contain baratie, mini-merry, mini-sunny, and striker";
        assert lib.assertMsg (
          config.waterSeven.hosts.baratie.role == "personal" && config.waterSeven.hosts.striker.role == "work"
        ) "baratie must remain the personal host and striker the work host";
        assert lib.assertMsg (
          deploymentReadyHostNames == [
            "mini-merry"
            "mini-sunny"
          ]
        ) "Only reviewed hosts may be deployment-ready during migration";
        assert lib.assertMsg (
          representativeHost.platform != "darwin"
          || (
            home.home.sessionVariables.LANG == "en_US.UTF-8"
            && home.home.sessionVariables.LC_CTYPE == "en_US.UTF-8"
            && representativeSystem.config.waterSeven.bootstrap.followUpSteps != [ ]
          )
        ) "Darwin hosts must declare a complete shell locale and manual permission guidance";
        assert lib.assertMsg
          (
            representativeHost.platform != "darwin"
            || (
              lib.subtractLists darwinPackageNames [
                "aerospace"
                "bitwarden-desktop"
                "brave"
                "raycast"
              ] == [ ]
              && darwinBrewNames == lib.optionals (representativeHost.role == "work") [ "mole" ]
              && lib.sort builtins.lessThan darwinCaskNames == lib.sort builtins.lessThan expectedDarwinCaskNames
              &&
                darwinMasApps == lib.optionalAttrs (representativeHost.role == "personal") {
                  "P-touch Editor" = 1453365242;
                }
              && lib.all (cask: !(cask.args.no_quarantine or false) || cask.name == "ghostty") darwinCasks
              && lib.any (cask: cask.name == "ghostty" && (cask.args.no_quarantine or false)) darwinCasks
              && (
                representativeHost.role != "personal"
                || lib.all (name: builtins.elem name darwinPackageNames) personalDarwinPackageNames
              )
              && representativeSystem.config.system.defaults.LaunchServices.LSQuarantine
              && lib.any (
                package:
                (package.pname or (lib.getName package)) == "raycast" && lib.versionAtLeast package.version "2.0"
              ) darwinSystemPackages
              && browserHandlers == null
              && lib.any (
                step: lib.hasInfix "Brave" step && lib.hasInfix "approve the macOS prompt" step
              ) representativeSystem.config.waterSeven.bootstrap.followUpSteps
            )
          )
          "Darwin applications must match the role package, Homebrew, MAS, quarantine, and interactive-consent policy";
        assert lib.assertMsg (
          representativeHost.platform != "nixos"
          || (
            home.xdg.mimeApps.enable
            && home.xdg.mimeApps.defaultApplications."text/html" == [ "brave-browser.desktop" ]
            &&
              home.xdg.mimeApps.defaultApplications."x-scheme-handler/http" == [
                "brave-browser.desktop"
              ]
            &&
              home.xdg.mimeApps.defaultApplications."x-scheme-handler/https" == [
                "brave-browser.desktop"
              ]
          )
        ) "NixOS must register Brave as the default handler for web content";
        pkgs.runCommand "water-seven-fleet-schema" { } "touch $out";

      requiredActions = lib.attrNames (
        lib.filterAttrs (_: action: action.support == "required") config.waterSeven.ux.desktop.actions
      );
      adapters = config.waterSeven.ux.desktop.adapters;
      missingActions = lib.mapAttrs (
        _: commands: lib.subtractLists (lib.attrNames commands) requiredActions
      ) adapters;
      completeAdapters = lib.all (missing: missing == [ ]) (lib.attrValues missingActions);
      uxContract =
        assert lib.assertMsg (
          lib.attrNames adapters == [
            "aerospace"
            "hyprland"
          ]
        ) "The desktop UX contract requires Aerospace and Hyprland adapters";
        assert lib.assertMsg completeAdapters
          "Required desktop actions missing from adapters: ${builtins.toJSON missingActions}";
        pkgs.runCommand "water-seven-ux-contract" { } "touch $out";

      formatting =
        pkgs.runCommand "water-seven-formatting"
          {
            nativeBuildInputs = [ pkgs.nixfmt-tree ];
            inherit source;
          }
          ''
            cp -R "$source" work
            chmod -R u+w work
            cd work
            ${lib.getExe pkgs.nixfmt-tree} --tree-root . --walk filesystem --ci
            touch "$out"
          '';

      nixLint =
        pkgs.runCommand "water-seven-nix-lint"
          {
            nativeBuildInputs = [
              pkgs.deadnix
              statix
            ];
            inherit source;
          }
          ''
            deadnix --fail "$source"
            statix check "$source"
            touch "$out"
          '';

      neovimFacts =
        pkgs.writeText "water-seven-neovim.lua"
          home.xdg.configFile."water-seven/generated/neovim.lua".text;
      tmuxFacts =
        pkgs.writeText "water-seven-tmux.conf"
          home.xdg.configFile."water-seven/generated/tmux.conf".text;
      gitConfig = home.xdg.configFile."git/config".source;
      miseConfig = home.xdg.configFile."mise/config.toml".source;
      ghosttyFacts = pkgs.writeText "water-seven-ghostty.conf" ''
        config-file = ${source}/native/ghostty/linux.conf
        keybind = ctrl+shift+t=unbind
        keybind = ctrl+shift+e=unbind
        keybind = ctrl+shift+o=unbind
      '';
      hyprlandPaths =
        pkgs.writeText "water-seven-hyprland-paths.lua"
          home.xdg.configFile."hypr/water_seven/paths.lua".text;
      hyprlandBindings =
        pkgs.writeText "water-seven-hyprland-bindings.lua"
          home.xdg.configFile."hypr/water_seven/bindings.lua".text;
      nativeConfig =
        pkgs.runCommand "water-seven-native-config"
          {
            nativeBuildInputs = [
              home.programs.git.package
              home.programs.neovim.finalPackage
              home.programs.tmux.package
              pkgs.bash
            ]
            ++ lib.optionals pkgs.stdenv.isLinux [
              pkgs.ghostty
              pkgs.hyprland
            ];
            inherit source;
          }
          ''
            export HOME="$TMPDIR/home"
            export XDG_CACHE_HOME="$HOME/.cache"
            export XDG_CONFIG_HOME="$HOME/.config"
            export XDG_DATA_HOME="$HOME/.local/share"
            export XDG_STATE_HOME="$HOME/.local/state"
            export XDG_RUNTIME_DIR="$TMPDIR/runtime"
            mkdir -p \
              "$XDG_CACHE_HOME" \
              "$XDG_CONFIG_HOME/nvim" \
              "$XDG_CONFIG_HOME/water-seven/generated" \
              "$XDG_DATA_HOME" \
              "$XDG_STATE_HOME" \
              "$XDG_RUNTIME_DIR"

            bash -n "$source/native/bash/bashrc"
            bash -n "$source/scripts/bootstrap.sh"
            bash -n "$source/scripts/check-darwin-default-browser.sh"
            test "$(git config --file ${gitConfig} --get init.defaultBranch)" = main
            test "$(git config --file ${gitConfig} --get pull.rebase)" = true
            test "$(git config --file ${gitConfig} --get push.default)" = simple
            test "$(git config --file ${gitConfig} --get rebase.updateRefs)" = true
            test "$(git config --file ${gitConfig} --get merge.conflictStyle)" = zdiff3
            test "$(git config --file ${gitConfig} --get diff.algorithm)" = histogram

            grep -Fx '[tools]' ${miseConfig}
            ! grep -F '=' ${miseConfig}

            cp "$source/native/nvim/init.lua" "$XDG_CONFIG_HOME/nvim/init.lua"
            cp "${neovimFacts}" "$XDG_CONFIG_HOME/water-seven/generated/neovim.lua"
            nvim --headless '+quitall'

            cp "${tmuxFacts}" "$XDG_CONFIG_HOME/water-seven/generated/tmux.conf"
            tmux -L water-seven-check -f "$source/native/tmux/tmux.conf" new-session -d
            tmux -L water-seven-check list-sessions >/dev/null
            tmux -L water-seven-check kill-server

            ${lib.optionalString pkgs.stdenv.isLinux ''
              mkdir -p "$XDG_CONFIG_HOME/ghostty"
              cp "$source/native/ghostty/config" "$XDG_CONFIG_HOME/ghostty/config"
              cp "${ghosttyFacts}" "$XDG_CONFIG_HOME/water-seven/generated/ghostty.conf"
              ghostty +validate-config --config-file="$XDG_CONFIG_HOME/ghostty/config"

              mkdir -p "$XDG_CONFIG_HOME/hypr/water_seven"
              cp "$source/native/hypr/hyprland.lua" "$XDG_CONFIG_HOME/hypr/hyprland.lua"
              cp "${hyprlandPaths}" "$XDG_CONFIG_HOME/hypr/water_seven/paths.lua"
              cp "${hyprlandBindings}" "$XDG_CONFIG_HOME/hypr/water_seven/bindings.lua"
              Hyprland --verify-config --config "$XDG_CONFIG_HOME/hypr/hyprland.lua"
            ''}

            touch "$out"
          '';
    in
    {
      checks = hostChecks // {
        fleet-schema = fleetSchema;
        inherit formatting;
        native-config = nativeConfig;
        nix-lint = nixLint;
        ux-contract = uxContract;
      };

      formatter = pkgs.nixfmt-tree;

      devShells.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.deadnix
          pkgs.nixfmt-tree
          statix
        ];
      };
    };
}

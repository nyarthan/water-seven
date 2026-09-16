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
      homePackageNames = map (package: package.pname or (lib.getName package)) home.home.packages;
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
      slackAutoUpdateProfile = lib.attrByPath [
        "environment"
        "etc"
        "water-seven/profiles/slack-disable-auto-update.mobileconfig"
        "source"
      ] null representativeSystem.config;
      personalCaskNames = [
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
      expectedDarwinCaskNames = [
        "brave-browser"
        "ghostty"
      ]
      ++ lib.optionals (representativeHost.role == "personal") personalCaskNames;
      personalDarwinPackageNames = [
        "google-chrome"
        "orbstack"
        "proton-vpn"
        "scroll-reverser"
        "slack"
        "verify-slack-update-policy"
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
            "baratie"
            "mini-merry"
            "mini-sunny"
          ]
        ) "Only reviewed hosts may be deployment-ready during migration";
        assert lib.assertMsg home.programs.atuin.settings.enter_accept
          "Atuin must retain enter_accept behavior during migration";
        assert lib.assertMsg (lib.versionAtLeast home.programs.mise.package.version "2026.7.0")
          "Mise must satisfy the minimum required version";
        assert lib.assertMsg (
          builtins.elem "workmux" homePackageNames
          && builtins.elem "pi-coding-agent" homePackageNames
          && home.programs.bash.shellAliases.wm == "workmux"
          && lib.hasInfix "agent: pi" home.xdg.configFile."workmux/config.yaml".text
          && lib.hasInfix "mode: window" home.xdg.configFile."workmux/config.yaml".text
          && lib.hasInfix "setup_wizard: false" home.xdg.configFile."workmux/config.yaml".text
          &&
            lib.hasInfix "/${config.waterSeven.projectsDirectory}/worktrees/{project}"
              home.xdg.configFile."workmux/config.yaml".text
          && home.home.file ? ".pi/agent/extensions/workmux-status.ts"
          && home.home.file ? ".agents/skills/workmux"
        ) "Shared workstations must provide the declarative Workmux and Pi workflow";
        assert lib.assertMsg (
          representativeHost.role != "personal"
          || (
            builtins.elem "twg" homePackageNames
            && lib.any (
              package:
              (package.pname or (lib.getName package)) == "pi-coding-agent"
              && lib.versionAtLeast (package.version or "0") "0.85.1"
            ) home.home.packages
          )
        ) "Personal hosts must preserve TWG and pi-coding-agent without downgrading pi";
        assert lib.assertMsg (
          representativeHost.role != "personal"
          || (
            slackAutoUpdateProfile != null
            && lib.any (
              step: lib.hasInfix "Slack" step && lib.hasInfix "slack-disable-auto-update.mobileconfig" step
            ) representativeSystem.config.waterSeven.bootstrap.followUpSteps
          )
        ) "Personal hosts must disable Slack self-updates through an approved managed profile";
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
                "raycast"
              ] == [ ]
              && !(builtins.elem "brave" darwinPackageNames)
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

      neovimInit = pkgs.writeText "water-seven-neovim-init.lua" home.programs.neovim.initLua;
      neovimPlugins = home.xdg.dataFile."nvim/site/pack/hm".source;
      tmuxFacts =
        pkgs.writeText "water-seven-tmux.conf"
          home.xdg.configFile."water-seven/generated/tmux.conf".text;
      gitConfig = home.xdg.configFile."git/config".source;
      miseConfig = home.xdg.configFile."mise/config.toml".source;
      workmuxConfig =
        pkgs.writeText "water-seven-workmux.yaml"
          home.xdg.configFile."workmux/config.yaml".text;
      workmuxExtension = home.home.file.".pi/agent/extensions/workmux-status.ts".source;
      workmuxSkill = home.home.file.".agents/skills/workmux".source;
      workmuxPackage = lib.findFirst (package: lib.getName package == "workmux") null home.home.packages;
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
              pkgs.nodejs_24
              pkgs.python3
              workmuxPackage
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
            bash -n "$source/scripts/prepare-darwin-homebrew-taps.sh"

            homebrew_prefix="$TMPDIR/homebrew-prefix"
            mkdir -p "$homebrew_prefix/Library/Taps"
            bash "$source/scripts/prepare-darwin-homebrew-taps.sh" "$homebrew_prefix"
            test ! -e "$homebrew_prefix/Library/Taps"

            mkdir -p "$homebrew_prefix/Library/Taps"
            touch "$homebrew_prefix/Library/Taps/preserved"
            if bash "$source/scripts/prepare-darwin-homebrew-taps.sh" "$homebrew_prefix"; then
              echo "the Homebrew migration guard removed or accepted a nonempty Taps directory" >&2
              exit 1
            fi
            test -f "$homebrew_prefix/Library/Taps/preserved"
            rm -rf "$homebrew_prefix/Library/Taps"

            mkdir -p "$homebrew_prefix/declarative-taps"
            ln -s "$homebrew_prefix/declarative-taps" "$homebrew_prefix/Library/Taps"
            bash "$source/scripts/prepare-darwin-homebrew-taps.sh" "$homebrew_prefix"
            test -L "$homebrew_prefix/Library/Taps"
            rm "$homebrew_prefix/Library/Taps"
            bash "$source/scripts/prepare-darwin-homebrew-taps.sh" "$homebrew_prefix"

            test "$(git config --file ${gitConfig} --get init.defaultBranch)" = main
            test "$(git config --file ${gitConfig} --get pull.rebase)" = true
            test "$(git config --file ${gitConfig} --get push.default)" = simple
            test "$(git config --file ${gitConfig} --get rebase.updateRefs)" = true
            test "$(git config --file ${gitConfig} --get merge.conflictStyle)" = zdiff3
            test "$(git config --file ${gitConfig} --get diff.algorithm)" = histogram

            grep -Fx '[tools]' ${miseConfig}
            ! grep -F '=' ${miseConfig}

            grep -Fx 'agent: pi' ${workmuxConfig}
            grep -Fx 'mode: window' ${workmuxConfig}
            grep -Fx 'setup_wizard: false' ${workmuxConfig}
            grep -Fx 'worktree_dir: "${home.home.homeDirectory}/${config.waterSeven.projectsDirectory}/worktrees/{project}"' ${workmuxConfig}
            grep -F 'pi.exec("workmux", ["register-agent"])' ${workmuxExtension}
            grep -F 'pi.on("ui_prompt_start"' ${workmuxExtension}
            grep -Fx 'name: workmux' ${workmuxSkill}/SKILL.md
            node --test "$source/native/pi/extensions/workmux-status.test.mjs"
            mkdir -p "$XDG_CONFIG_HOME/workmux"
            cp ${workmuxConfig} "$XDG_CONFIG_HOME/workmux/config.yaml"
            workmux --version
            workmux completions bash >/dev/null

            ${lib.optionalString (slackAutoUpdateProfile != null) ''
              python - ${slackAutoUpdateProfile} <<'PY'
              import plistlib
              import sys

              with open(sys.argv[1], "rb") as profile_file:
                  profile = plistlib.load(profile_file)

              assert profile["PayloadIdentifier"] == "dev.water-seven.slack.disable-auto-update"
              preferences, = profile["PayloadContent"]
              assert preferences["PayloadType"] == "com.tinyspeck.slackmacgap"
              assert preferences["AutoUpdate"] is False
              PY
            ''}

            mkdir -p "$XDG_DATA_HOME/nvim/site/pack"
            ln -s "${neovimPlugins}" "$XDG_DATA_HOME/nvim/site/pack/hm"
            cat > "$XDG_CONFIG_HOME/nvim/init.lua" <<'LUA'
            vim.g.water_seven_config_loaded_before_init = vim.g.water_seven_config_directory ~= nil
            dofile("${neovimInit}")
            LUA
            cat > neovim-check.lua <<'LUA'
            local ok, verification_error = xpcall(function()
              assert(
                not vim.g.water_seven_config_loaded_before_init,
                "the Water Seven config loaded before the managed init.lua"
              )
              assert(vim.g.water_seven_config_directory, "the selected config did not finish loading")
              assert(
                vim.fn.filereadable(vim.g.water_seven_config_directory .. "/init.lua") == 1,
                "the loaded config has no init.lua"
              )
              assert(vim.fn.exepath("nil") ~= "", "nil is not available")
              assert(vim.fn.exepath("nixd") == "", "nixd is unexpectedly available")
              assert(vim.lsp.config.nil_ls ~= nil, "nil_ls is not configured")
              assert(package.loaded["mini.files"], "MiniFiles is not loaded")
              assert(package.loaded["snacks"], "Snacks is not loaded")
              assert(package.loaded["trouble"], "Trouble is not loaded")
            end, debug.traceback)
            if not ok then
              io.stderr:write(verification_error .. "\n")
              os.exit(1)
            end
            vim.cmd("quitall")
            LUA

            export NVIM_CONFIG_DIR="$source/native/nvim"
            nvim --headless "+luafile neovim-check.lua"

            export NVIM_CONFIG_DIR="$TMPDIR/missing-neovim-config"
            nvim --headless "+luafile neovim-check.lua"

            cp "${tmuxFacts}" "$XDG_CONFIG_HOME/water-seven/generated/tmux.conf"
            tmux -L water-seven-check -f "$source/native/tmux/tmux.conf" new-session -d
            tmux -L water-seven-check list-sessions >/dev/null
            test "$(tmux -L water-seven-check show-options -gv prefix)" = C-b
            test "$(tmux -L water-seven-check show-options -gv default-terminal)" = tmux-256color
            test "$(tmux -L water-seven-check show-options -gv mode-keys)" = vi
            test "$(tmux -L water-seven-check show-options -gv status-keys)" = vi
            test "$(tmux -L water-seven-check show-options -gv renumber-windows)" = off
            test "$(tmux -L water-seven-check show-options -gv focus-events)" = on
            test "$(tmux -L water-seven-check show-options -gv extended-keys)" = on
            test "$(tmux -L water-seven-check show-options -gv extended-keys-format)" = csi-u
            test "$(tmux -L water-seven-check show-options -gv allow-passthrough)" = on
            test "$(tmux -L water-seven-check show-options -gv set-titles-string)" = '#{pane_title}'
            tmux -L water-seven-check list-keys -T prefix c | grep -F 'new-window -c "#{pane_current_path}"'
            tmux -L water-seven-check list-keys -T prefix w | grep -F 'display-popup'
            tmux -L water-seven-check list-keys -T prefix w | grep -F 'workmux dashboard'
            tmux -L water-seven-check list-keys -T root M-h | grep -F 'select-pane -L'
            ! tmux -L water-seven-check list-keys | grep -F '$SHELL -lc work'
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

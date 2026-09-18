{ config, inputs, ... }:
let
  projectsDirectory = config.waterSeven.projectsDirectory;
in
{
  flake.modules.homeManager.shared-workstation =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      workmux = inputs.workmux.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ../../../patches/workmux/declarative-setup.patch
          ../../../patches/workmux/ignore-control-b.patch
        ];
      });
    in
    {
      home.packages = [ workmux ];

      programs.bash.shellAliases.wm = "workmux";

      home.activation.removeLegacyWorkmuxSetupState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        rm -f ${lib.escapeShellArg "${config.xdg.stateHome}/workmux/setup.json"}
      '';

      xdg.configFile."workmux/config.yaml".text = ''
        agent: pi
        mode: window
        nerdfont: false
        setup_wizard: false
        worktree_dir: "${config.home.homeDirectory}/${projectsDirectory}/worktrees/{project}"

        panes:
          - command: <agent>
            focus: true
          - split: horizontal
      '';
    };
}

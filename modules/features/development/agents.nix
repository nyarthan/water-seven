_: {
  flake.modules.homeManager.shared-workstation =
    { config, lib, ... }:
    {
      home.file.".agents/skills" = {
        source = ../../../native/agents/skills;
        force = true;
      };

      home.activation.removeLegacySkillInstallerState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        rm -f ${lib.escapeShellArg "${config.home.homeDirectory}/.agents/.skill-lock.json"}
      '';
    };
}

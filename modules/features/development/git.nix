{
  flake.modules.homeManager.shared-workstation = {
    programs = {
      delta = {
        enable = true;
        enableGitIntegration = true;
        options.side-by-side = false;
      };

      git = {
        enable = true;
        includes = [ { path = "~/.config/git/identity"; } ];
        lfs.enable = true;
        settings = {
          branch.sort = "-committerdate";
          commit.verbose = true;
          core.excludesFile = "~/.config/git/ignore";
          diff = {
            algorithm = "histogram";
            colorMoved = "default";
            renames = "copies";
          };
          fetch = {
            prune = true;
            pruneTags = true;
          };
          help.autocorrect = "prompt";
          init.defaultBranch = "main";
          merge.conflictStyle = "zdiff3";
          pull.rebase = true;
          push = {
            autoSetupRemote = true;
            default = "simple";
            followTags = false;
          };
          rebase = {
            autoStash = false;
            updateRefs = true;
          };
          rerere.enabled = true;
          tag.sort = "version:refname";
        };
      };
    };

    xdg.configFile = {
      "git/identity.example".text = ''
        # Copy this file to ~/.config/git/identity and keep it private.
        [user]
          name = Your Name
          email = you@example.com

        # Optional SSH commit signing:
        # [gpg]
        #   format = ssh
        # [user]
        #   signingKey = ~/.ssh/id_ed25519.pub
        # [commit]
        #   gpgSign = true
      '';

      "git/ignore".text = ''
        .DS_Store
        .serena/
      '';
    };
  };

  flake.modules.darwin.shared-workstation = {
    waterSeven.bootstrap.followUpSteps = [
      "Git: copy ~/.config/git/identity.example to ~/.config/git/identity and set the private identity."
    ];
  };
}

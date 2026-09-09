{
  flake.modules.nixos.shared-workstation = {
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = true;
    };
  };

  flake.modules.darwin.shared-workstation = {
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = true;
    };
  };
}

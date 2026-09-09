{
  flake.modules.darwin.host-baratie = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.utm ];
  };
}

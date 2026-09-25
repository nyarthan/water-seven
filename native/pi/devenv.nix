{ pkgs, ... }:

{
  env.FORCE_COLOR = 3;

  languages.javascript = {
    enable = true;
    package = pkgs.nodejs_26;
    lsp.enable = false;
    pnpm.enable = true;
  };

  packages = [ pkgs.oxfmt ];

  enterShell = ''
    export PATH="$DEVENV_ROOT/node_modules/.bin:$PATH"
  '';

  tasks = {
    "pi:format".exec = "oxfmt";
    "pi:format-check".exec = "oxfmt --check";
    "pi:types".exec = "tsc";
  };
}

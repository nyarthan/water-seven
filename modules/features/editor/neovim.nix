{ config, ... }:
let
  projectsDirectory = config.waterSeven.projectsDirectory;
in
{
  flake.modules.homeManager.shared-workstation =
    { config, pkgs, ... }:
    let
      checkout = "${config.home.homeDirectory}/${projectsDirectory}/water-seven";
      liveConfig = "${checkout}/native/nvim";
      frozenConfig = pkgs.runCommand "water-seven-neovim-config" { } ''
        mkdir -p "$out"
        cp -R ${../../../native/nvim}/. "$out/"
      '';

      # nixpkgs builds sqls without FTS5, so its SQLite driver cannot open
      # tables created with `USING fts5` and drops the whole connection.
      sqls-fts5 = pkgs.sqls.overrideAttrs (previous: {
        tags = (previous.tags or [ ]) ++ [ "sqlite_fts5" ];
      });
    in
    {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        vimAlias = true;
        withNodeJs = false;
        withPython3 = false;
        withRuby = false;

        initLua = ''
          local config_directory = vim.env.NVIM_CONFIG_DIR
          if not (config_directory and vim.fn.filereadable(config_directory .. "/init.lua") == 1) then
            config_directory = "${frozenConfig}"
          end
          vim.opt.rtp:prepend(config_directory)
          vim.cmd.packloadall()
          dofile(config_directory .. "/init.lua")
          vim.g.water_seven_config_directory = config_directory
        '';

        plugins = with pkgs.vimPlugins; [
          {
            plugin = conform-nvim;
            optional = false;
          }
          {
            plugin = mini-nvim;
            optional = false;
          }
          {
            plugin = otter-nvim;
            optional = false;
          }
          {
            plugin = nvim-treesitter.withAllGrammars;
            optional = false;
          }
          {
            plugin = nvim-ts-autotag;
            optional = false;
          }
          {
            plugin = nvim-ts-context-commentstring;
            optional = false;
          }
          {
            plugin = snacks-nvim;
            optional = false;
          }
          {
            plugin = trouble-nvim;
            optional = false;
          }
          {
            plugin = nvim-lspconfig;
            optional = false;
          }
        ];

        extraPackages = with pkgs; [
          deno
          fd
          lua-language-server
          nil
          nix-doc
          nixfmt
          oxfmt
          ripgrep
          rust-analyzer
          shellcheck
          sql-formatter
          sqls-fts5
          stdenv.cc.cc
          stylua
          tailwindcss-language-server
          taplo
          typescript-language-server
          universal-ctags
          vscode-langservers-extracted
          vue-language-server
          yaml-language-server
        ];
      };

      home.sessionVariables.NVIM_CONFIG_DIR = liveConfig;
    };
}

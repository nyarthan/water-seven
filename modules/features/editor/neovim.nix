{ config, ... }:
let
  projectsDirectory = config.waterSeven.projectsDirectory;
in
{
  flake.modules.homeManager.shared-workstation =
    { config, pkgs, ... }:
    let
      checkout = "${config.home.homeDirectory}/${projectsDirectory}/water-seven";
      treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (
        parsers: with parsers; [
          bash
          json
          lua
          markdown
          markdown_inline
          nix
          query
          toml
          vim
          vimdoc
          yaml
        ]
      );
    in
    {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        sideloadInitLua = true;
        plugins = with pkgs.vimPlugins; [
          nvim-lspconfig
          plenary-nvim
          telescope-nvim
          treesitter
        ];
        extraPackages = with pkgs; [
          bash-language-server
          lua-language-server
          nil
          nixfmt
          ripgrep
          shellcheck
          shfmt
          stylua
        ];
      };

      xdg.configFile = {
        "nvim/init.lua".source = config.lib.file.mkOutOfStoreSymlink "${checkout}/native/nvim/init.lua";
        "water-seven/generated/neovim.lua".text = ''
          -- Generated tool selection. Do not edit.
          vim.g.water_seven_language_servers = { "bashls", "lua_ls", "nil_ls" }
        '';
      };
    };
}

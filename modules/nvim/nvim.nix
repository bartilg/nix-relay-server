{ config, pkgs, lib, ... }:
let
  vimPlugins = pkgs.vimPlugins;
in
{
  programs.neovim = {
    enable   = true;
    package  = pkgs.neovim;
    vimAlias = true;

    plugins = with vimPlugins; [ vim-nix ];

    extraConfig = ''
      lua << EOF
      require'nvim-treesitter.configs'.setup {
        ensure_installed = { "nix" };
        highlight = { enable = true };
      }
      EOF
    '';
  };
}

{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      nvchad
      nixd
      nixfmt
      bash-language-server
      python3Packages.flake8
    ];

    sessionVariables.EDITOR = "nvim";
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    withPython3 = false;
    withRuby = false;

    plugins = with pkgs.vimPlugins; [
      vim-nix
    ];
  };
}

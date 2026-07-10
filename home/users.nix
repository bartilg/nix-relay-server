{ pkgs, home-manager, ... }:

{
  bart = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      ./core.nix
      ../modules/home/shell/zsh.nix
      ../modules/home/nvim/nvchad.nix
      ../modules/home/gh.nix
      {
        home = {
          username = "bart";
          homeDirectory = "/home/bart";
        };
      }
    ];
  };
}

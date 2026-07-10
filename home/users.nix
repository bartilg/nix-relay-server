{ pkgs, home-manager, ... }:

{
  bart = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      ./core.nix
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

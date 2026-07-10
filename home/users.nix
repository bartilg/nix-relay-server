{ pkgs, home-manager, ... }:

{
  bart = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      ./core.nix
    ];
    extraSpecialArgs = {
      username = "bart";
    };
  };
}

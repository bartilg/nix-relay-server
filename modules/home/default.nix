{ ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    sharedModules = [
      ./shell/zsh.nix
      ./nvim/nvchad.nix
      ./gh.nix
    ];
  };
}

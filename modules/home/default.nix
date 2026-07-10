{ ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";

    sharedModules = [
      ./shell/zsh.nix
      ./nvim/nvchad.nix
      ./gh.nix
    ];
  };
}

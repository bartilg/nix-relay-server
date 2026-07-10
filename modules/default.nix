{ ... }:

{
  imports = [
    ./docker.nix
    ./shell
    ./home
    ./monitoring
    ./nvim/nvchad.nix
  ];
}

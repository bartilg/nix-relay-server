# ~/.config/nixpkgs/shell/gh.nix
{ pkgs, ... }:

{
  programs.gh = {
    enable = true;
  };
}

# ~/.config/nixpkgs/shell/zsh.nix
{ pkgs, ... }:

{
  # Configure Zsh for the user
  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "z"
        "sudo"
      ];
    };
  };
}

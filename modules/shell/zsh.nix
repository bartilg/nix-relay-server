{ pkgs, config, lib, ... }: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    ohMyZsh = {
      enable = true;
      theme = "agnoster";
      plugins = [
        "colored-man-pages"
        "colorize"
        "command-not-found"
        "docker"
        "docker-compose"
        "helm"
        "emoji"
        "git"
        "ssh"
        "sudo"
        "safe-paste"
        "vi-mode"
      ];
      customPkgs = [
        pkgs.nix-zsh-completions
      ];
    };
  };

  # Ensure zsh is available system-wide
  environment.shells = [ pkgs.zsh ];
}

{ ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
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
    };
  };
}

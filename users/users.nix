{ pkgs, ... }:

{
  users.users.bart = {
    isNormalUser = true;
    description = "Bart";
    home = "/home/bart";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICKSOk+E7hs6gPApVu6oxM/77jDXL/RkA1nrGCuF6qAm"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuORuew2uz+9107WR2MItoPg1Cg7xtul44zGwnxE+LN bart@shiki" # shiki laptop
    ];
  };

  home-manager.users.bart = {
    imports = [
      ../home/core.nix
    ];

    home = {
      username = "bart";
      homeDirectory = "/home/bart";
    };
  };
}

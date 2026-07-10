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

  # Give bart direct ownership of the system config repo
  systemd.tmpfiles.rules = [
    "Z /etc/nixos - bart users - -"
    # Empty marker so zsh-newuser-install doesn't run; real config is in /etc/zshrc
    "f /home/bart/.zshrc 0644 bart users - -"
  ];

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

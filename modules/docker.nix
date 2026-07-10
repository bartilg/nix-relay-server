{ pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    rootless.enable = false;

    daemon.settings = {
      "log-driver" = "journald";
      "log-opts" = {
        tag = "{{.Name}}";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    docker
  ];
}

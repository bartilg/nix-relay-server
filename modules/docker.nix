{ pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;

    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" ];
    };

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

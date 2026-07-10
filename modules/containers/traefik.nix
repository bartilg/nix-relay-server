{ pkgs, ... }:

let
  stackDir = ../../stacks/traefik;
  compose = "${stackDir}/compose.yaml";
  envFile = "/var/lib/homelab/traefik/traefik.env";
in
{
  systemd.services.homelab-traefik = {
    description = "Traefik Docker Compose stack";
    after = [
      "docker.service"
      "homelab-docker-network-proxy.service"
    ];
    requires = [
      "docker.service"
      "homelab-docker-network-proxy.service"
    ];
    wantedBy = [ "multi-user.target" ];

    unitConfig.ConditionPathExists = envFile;

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "${stackDir}";
    };

    preStart = ''
      ${pkgs.coreutils}/bin/mkdir -p /var/lib/homelab/traefik
      if [ ! -e /var/lib/homelab/traefik/acme.json ]; then
        ${pkgs.coreutils}/bin/install -m 600 /dev/null /var/lib/homelab/traefik/acme.json
      fi
    '';

    script = ''
      ${pkgs.docker}/bin/docker compose \
        --env-file ${envFile} \
        -f ${compose} \
        --project-name traefik \
        up -d --remove-orphans
    '';

    preStop = ''
      ${pkgs.docker}/bin/docker compose \
        --env-file ${envFile} \
        -f ${compose} \
        --project-name traefik \
        down
    '';
  };
}

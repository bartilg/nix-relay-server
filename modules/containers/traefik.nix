{ pkgs, ... }:

let
  stackDir = ../../stacks/traefik;
  compose = "${stackDir}/compose.yaml";
  envFile = "/var/lib/homelab/traefik/traefik.env";
  composeUp = pkgs.writeShellScript "homelab-traefik-up" ''
    exec ${pkgs.docker}/bin/docker compose \
      --env-file ${envFile} \
      -f ${compose} \
      --project-name traefik \
      up -d --remove-orphans
  '';
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
      ExecStart = composeUp;
      # Reload re-runs `up -d` without the `down` a restart would trigger
      ExecReload = composeUp;
    };

    preStart = ''
      ${pkgs.coreutils}/bin/mkdir -p /var/lib/homelab/traefik
      if [ ! -e /var/lib/homelab/traefik/acme.json ]; then
        ${pkgs.coreutils}/bin/install -m 600 /dev/null /var/lib/homelab/traefik/acme.json
      fi
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

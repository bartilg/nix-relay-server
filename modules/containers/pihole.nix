{ pkgs, ... }:

let
  stackDir = ../../stacks/pihole;
  compose = "${stackDir}/compose.yaml";
  envFile = "/var/lib/homelab/pihole/pihole.env";
in
{
  systemd.services.homelab-pihole = {
    description = "Pi-hole Docker Compose stack";
    after = [
      "docker.service"
      "homelab-docker-network-proxy.service"
    ];
    requires = [
      "docker.service"
      "homelab-docker-network-proxy.service"
    ];
    wantedBy = [ "multi-user.target" ];

    unitConfig.ConditionPathExists = [
      envFile
      "/var/lib/homelab/pihole/nebula-sync.env"
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "${stackDir}";
    };

    preStart = ''
      ${pkgs.coreutils}/bin/mkdir -p \
        /var/lib/homelab/pihole/etc-pihole \
        /var/lib/homelab/pihole/etc-dnsmasq.d
    '';

    script = ''
      ${pkgs.docker}/bin/docker compose \
        --env-file ${envFile} \
        -f ${compose} \
        --project-name pihole \
        up -d --remove-orphans
    '';

    preStop = ''
      ${pkgs.docker}/bin/docker compose \
        --env-file ${envFile} \
        -f ${compose} \
        --project-name pihole \
        down
    '';
  };
}

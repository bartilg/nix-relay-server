{ pkgs, ... }:

{
  systemd.services.homelab-docker-network-proxy = {
    description = "Create the shared homelab Docker proxy network";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      if ! ${pkgs.docker}/bin/docker network inspect proxy >/dev/null 2>&1; then
        ${pkgs.docker}/bin/docker network create \
          --driver bridge \
          --opt com.docker.network.bridge.name=br-proxy \
          proxy
      else
        bridge_name="$(${pkgs.docker}/bin/docker network inspect proxy --format '{{ index .Options "com.docker.network.bridge.name" }}')"
        if [ "$bridge_name" != "br-proxy" ]; then
          echo "Recreating Docker network 'proxy' with stable bridge 'br-proxy'." >&2
          ${pkgs.systemd}/bin/systemctl stop homelab-pihole.service homelab-traefik.service 2>/dev/null || true
          attached_containers="$(${pkgs.docker}/bin/docker network inspect proxy --format '{{ range .Containers }}{{ .Name }} {{ end }}')"
          for container in $attached_containers; do
            ${pkgs.docker}/bin/docker network disconnect -f proxy "$container" || true
          done
          ${pkgs.docker}/bin/docker network rm proxy
          ${pkgs.docker}/bin/docker network create \
            --driver bridge \
            --opt com.docker.network.bridge.name=br-proxy \
            proxy
        fi
      fi
    '';
  };
}

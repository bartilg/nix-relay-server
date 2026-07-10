{ pkgs, ... }:

let
  # Bridge name must stay "br-proxy": the firewall trusts that interface
  ensureNetwork = pkgs.writeShellScript "homelab-ensure-proxy-network" ''
    if ${pkgs.docker}/bin/docker network inspect proxy >/dev/null 2>&1; then
      bridge="$(${pkgs.docker}/bin/docker network inspect proxy \
        --format '{{ index .Options "com.docker.network.bridge.name" }}')"
      if [ "$bridge" != "br-proxy" ]; then
        echo "Docker network 'proxy' exists with bridge '$bridge'; expected 'br-proxy'." >&2
        echo "Stop the Compose stacks and remove the incompatible network before rebuilding." >&2
        exit 1
      fi
    else
      ${pkgs.docker}/bin/docker network create \
        --driver bridge \
        --opt com.docker.network.bridge.name=br-proxy \
        proxy
    fi
  '';
in
{
  systemd.services.homelab-docker-network-proxy = {
    description = "Create the shared homelab Docker proxy network";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = ensureNetwork;
      ExecReload = ensureNetwork;
    };

    reloadIfChanged = true;
  };
}

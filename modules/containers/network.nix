{ pkgs, ... }:

let
  # Bridge name must stay "br-proxy": the firewall trusts that interface
  ensureNetwork = pkgs.writeShellScript "homelab-ensure-proxy-network" ''
    ${pkgs.docker}/bin/docker network inspect proxy >/dev/null 2>&1 || \
      ${pkgs.docker}/bin/docker network create \
        --driver bridge \
        --opt com.docker.network.bridge.name=br-proxy \
        proxy
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
      # Reload re-checks the network without stopping the unit, which would
      # propagate to the stacks through their Requires=
      ExecReload = ensureNetwork;
    };
  };
}

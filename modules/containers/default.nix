{ pkgs, ... }:

{
  imports = [
    ./network.nix
    ./pihole.nix
    ./traefik.nix
  ];

  # switch-to-configuration only restarts units whose definition changed, so
  # docker networks/containers removed out-of-band are never recreated.
  # Reconcile on every activation: reload-or-restart reloads active units
  # (re-running the idempotent ensure/`up -d` scripts without a stop, which
  # would cascade through Requires=) and starts inactive or failed ones.
  # Env-file ConditionPathExists still gates the stacks. Skipped at boot,
  # where wantedBy handles startup. The network goes first, blocking, so the
  # stacks find it.
  system.activationScripts.homelabStacksReconcile = ''
    if [ -e /run/systemd/system ]; then
      ${pkgs.systemd}/bin/systemctl reload-or-restart \
        homelab-docker-network-proxy.service || true
      ${pkgs.systemd}/bin/systemctl reload-or-restart --no-block \
        homelab-pihole.service homelab-traefik.service || true
    fi
  '';
}

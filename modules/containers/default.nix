{ pkgs, ... }:

{
  imports = [
    ./network.nix
    ./pihole.nix
    ./traefik.nix
  ];

  # switch-to-configuration only restarts units whose definition changed, so
  # containers removed out-of-band are never recreated. Reload the stacks on
  # every activation to re-run `compose up -d` (skipped if the unit is not
  # active, e.g. its env file is missing; skipped at boot where wantedBy
  # handles startup).
  system.activationScripts.homelabStacksReconcile = ''
    if [ -e /run/systemd/system ]; then
      ${pkgs.systemd}/bin/systemctl try-reload-or-restart --no-block \
        homelab-pihole.service homelab-traefik.service || true
    fi
  '';
}

{
  hostName = "nix01";

  # Pi-hole config leader: runs Nebula Sync and pushes to the replicas
  piholeNebulaSyncLeader = true;

  # Staggered per host so both DNS relays never restart at the same time
  autoUpgradeDates = "Mon 04:30";

  firewall = {
    trustedInterfaces = [ ];
  };
}

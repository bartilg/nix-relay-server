{
  hostName = "iris";

  # Pi-hole replica: receives config from the leader, never runs Nebula Sync
  piholeNebulaSyncLeader = false;

  # Staggered per host so both DNS relays never restart at the same time
  autoUpgradeDates = "Mon 05:30";

  firewall = {
    trustedInterfaces = [ ];
  };
}

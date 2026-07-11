{
  hostName = "hermes";

  # Pi-hole replica: receives config from the leader, never runs Nebula Sync
  piholeNebulaSyncLeader = false;

  # Staggered per host so both DNS relays never restart at the same time
  autoUpgradeDates = "Sat  06:00";

  firewall = {
    trustedInterfaces = [ ];
  };
}

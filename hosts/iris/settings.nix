{
  hostName = "iris";

  # Pi-hole replica: receives config from the leader, never runs Nebula Sync
  piholeNebulaSyncLeader = false;

  firewall = {
    trustedInterfaces = [ ];
  };
}

{
  hostName = "nix01";

  # Pi-hole config leader: runs Nebula Sync and pushes to the replicas
  piholeNebulaSyncLeader = true;

  firewall = {
    trustedInterfaces = [ ];
  };
}

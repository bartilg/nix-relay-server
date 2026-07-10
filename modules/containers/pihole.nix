{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.homelabPihole;
  stackDir = ../../stacks/pihole;
  composeFiles = [
    "${stackDir}/compose.yaml"
  ]
  ++ lib.optional cfg.nebulaSync.enable "${stackDir}/compose.nebula-sync.yaml";
  mkComposeStack = import ./compose-stack.nix { inherit lib pkgs; };
in
{
  options.services.homelabPihole.nebulaSync.enable = lib.mkEnableOption ''
    running Nebula Sync alongside Pi-hole. Enable only on the leader host;
    replicas receive its changes and must not run their own sync
  '';

  config = {
    systemd.services.homelab-pihole = mkComposeStack {
      name = "pihole";
      description = "Pi-hole Docker Compose stack";
      projectDir = stackDir;
      inherit composeFiles;
    };
  };
}

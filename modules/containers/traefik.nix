{ lib, pkgs, ... }:

let
  stackDir = ../../stacks/traefik;
  compose = "${stackDir}/compose.yaml";
  mkComposeStack = import ./compose-stack.nix { inherit lib pkgs; };
in
{
  systemd.services.homelab-traefik = mkComposeStack {
    name = "traefik";
    description = "Traefik Docker Compose stack";
    projectDir = stackDir;
    composeFiles = [ compose ];
  };
}

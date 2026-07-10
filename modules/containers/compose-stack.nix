{ lib, pkgs }:

{
  name,
  description,
  projectDir,
  composeFiles,
}:

let
  composeArgs = lib.escapeShellArgs (
    lib.concatMap (file: [
      "--file"
      (toString file)
    ]) composeFiles
  );
  compose = "${pkgs.docker}/bin/docker compose ${composeArgs}";
  reconcile = pkgs.writeShellScript "homelab-${name}-reconcile" ''
    exec ${compose} up \
      --detach \
      --remove-orphans \
      --pull always \
      --wait \
      --wait-timeout 180
  '';
in
{
  inherit description;

  after = [
    "docker.service"
    "homelab-docker-network-proxy.service"
  ];
  requires = [
    "docker.service"
    "homelab-docker-network-proxy.service"
  ];
  wantedBy = [ "multi-user.target" ];

  reloadIfChanged = true;

  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
    TimeoutStartSec = "5min";
    WorkingDirectory = toString projectDir;
    ExecStart = reconcile;
    ExecReload = reconcile;
  };

  preStop = ''
    ${compose} down
  '';
}

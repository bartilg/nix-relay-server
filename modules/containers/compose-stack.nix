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
  ensureNetwork = pkgs.writeShellScript "homelab-ensure-proxy-network" ''
    if ! ${pkgs.docker}/bin/docker network inspect proxy >/dev/null 2>&1; then
      ${pkgs.docker}/bin/docker network create \
        --driver bridge \
        --opt com.docker.network.bridge.name=br-proxy \
        proxy \
        || ${pkgs.docker}/bin/docker network inspect proxy >/dev/null
    fi

    bridge="$(${pkgs.docker}/bin/docker network inspect proxy \
      --format '{{ index .Options "com.docker.network.bridge.name" }}')"
    if [ "$bridge" != "br-proxy" ]; then
      echo "Docker network 'proxy' uses bridge '$bridge'; expected 'br-proxy'." >&2
      exit 1
    fi
  '';
  reconcile = pkgs.writeShellScript "homelab-${name}-reconcile" ''
    ${ensureNetwork}
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

  after = [ "docker.service" ];
  requires = [ "docker.service" ];
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

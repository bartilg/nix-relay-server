{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.homelabPihole;
  stackDir = ../../stacks/pihole;
  envFile = "/var/lib/homelab/pihole/pihole.env";
  nebulaSyncEnvFile = "/var/lib/homelab/pihole/nebula-sync.env";
  composeFiles = [
    "${stackDir}/compose.yaml"
  ]
  ++ lib.optional cfg.nebulaSync.enable "${stackDir}/compose.nebula-sync.yaml";
  composeFileArgs = lib.concatMapStringsSep " " (f: "-f ${f}") composeFiles;
  composeUp = pkgs.writeShellScript "homelab-pihole-up" ''
    exec ${pkgs.docker}/bin/docker compose \
      --env-file ${envFile} \
      ${composeFileArgs} \
      --project-name pihole \
      up -d --remove-orphans
  '';
in
{
  options.services.homelabPihole.nebulaSync.enable = lib.mkEnableOption ''
    running Nebula Sync alongside Pi-hole. Enable only on the leader host;
    replicas receive its changes and must not run their own sync
  '';

  config = {
    systemd.services.homelab-pihole = {
      description = "Pi-hole Docker Compose stack";
      after = [
        "docker.service"
        "homelab-docker-network-proxy.service"
      ];
      requires = [
        "docker.service"
        "homelab-docker-network-proxy.service"
      ];
      wantedBy = [ "multi-user.target" ];

      unitConfig.ConditionPathExists = [
        envFile
      ]
      ++ lib.optional cfg.nebulaSync.enable nebulaSyncEnvFile;

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = "${stackDir}";
        ExecStart = composeUp;
        # Reload re-runs `up -d` without the `down` a restart would trigger
        ExecReload = composeUp;
      };

      preStart = ''
        ${pkgs.coreutils}/bin/mkdir -p \
          /var/lib/homelab/pihole/etc-pihole \
          /var/lib/homelab/pihole/etc-dnsmasq.d
      '';

      preStop = ''
        ${pkgs.docker}/bin/docker compose \
          --env-file ${envFile} \
          ${composeFileArgs} \
          --project-name pihole \
          down
      '';
    };
  };
}

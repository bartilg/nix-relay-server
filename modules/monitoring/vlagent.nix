{ config, lib, ... }:

let
  cfg = config.services.homelabMonitoring;
in
{
  options.services.homelabMonitoring = {
    enable = lib.mkEnableOption "homelab monitoring forwarding";

    victoriaLogsRemoteWriteUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "VictoriaLogs native insert endpoint.";
    };

    vlagent = {
      listenAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1:9429";
        description = "Address where vlagent accepts local journal uploads.";
      };

      maxDiskUsagePerUrl = lib.mkOption {
        type = lib.types.str;
        default = "2GB";
        description = "Maximum on-disk queue size for each VictoriaLogs remote write URL.";
      };

      insertMaxQueueDuration = lib.mkOption {
        type = lib.types.str;
        default = "5s";
        description = "Maximum time vlagent waits for insert queue capacity before responding to local upload clients.";
      };

      journalUploadNetworkTimeout = lib.mkOption {
        type = lib.types.str;
        default = "2min";
        description = "Network timeout used by systemd-journal-upload when sending logs to local vlagent.";
      };

      journaldStreamFields = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "_HOSTNAME"
          "_SYSTEMD_UNIT"
          "SYSLOG_IDENTIFIER"
          "CONTAINER_NAME"
          "CONTAINER_TAG"
          "_TRANSPORT"
          "PRIORITY"
        ];
        description = "Journald fields used as VictoriaLogs stream fields.";
      };

      journaldIgnoreFields = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "__CURSOR"
          "__MONOTONIC_TIMESTAMP"
          "_AUDIT_LOGINUID"
          "_AUDIT_SESSION"
          "_BOOT_ID"
          "_CAP_EFFECTIVE"
          "_CMDLINE"
          "_COMM"
          "_EXE"
          "_GID"
          "_MACHINE_ID"
          "_PID"
          "_RUNTIME_SCOPE"
          "_SELINUX_CONTEXT"
          "_SOURCE_REALTIME_TIMESTAMP"
          "_STREAM_ID"
          "_SYSTEMD_CGROUP"
          "_SYSTEMD_INVOCATION_ID"
          "_SYSTEMD_SLICE"
          "_UID"
        ];
        description = "Noisy journald fields dropped before shipping logs.";
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.victoriaLogsRemoteWriteUrl != "") {
    services.vlagent = {
      enable = true;
      remoteWrite = {
        url = cfg.victoriaLogsRemoteWriteUrl;
        maxDiskUsagePerUrl = cfg.vlagent.maxDiskUsagePerUrl;
      };

      extraArgs = [
        "-httpListenAddr=${cfg.vlagent.listenAddress}"
        "-insert.maxQueueDuration=${cfg.vlagent.insertMaxQueueDuration}"
        "-loggerFormat=json"
        "-journald.streamFields=${lib.concatStringsSep "," cfg.vlagent.journaldStreamFields}"
        "-journald.ignoreFields=${lib.concatStringsSep "," cfg.vlagent.journaldIgnoreFields}"
      ];
    };

    services.journald.upload = {
      enable = true;
      settings.Upload = {
        URL = "http://${cfg.vlagent.listenAddress}/insert/journald";
        NetworkTimeoutSec = cfg.vlagent.journalUploadNetworkTimeout;
      };
    };

    systemd.services."systemd-journal-upload" = {
      after = [ "vlagent.service" ];
      requires = [ "vlagent.service" ];
    };
  };
}

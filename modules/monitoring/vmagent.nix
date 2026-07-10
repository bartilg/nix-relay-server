{ config, lib, ... }:

let
  cfg = config.services.homelabMonitoring;
in
{
  options.services.homelabMonitoring = {
    victoriaMetricsRemoteWriteUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "VictoriaMetrics remote_write endpoint.";
    };

    vmagent = {
      scrapeInterval = lib.mkOption {
        type = lib.types.str;
        default = "10s";
        description = "Prometheus scrape interval used by vmagent.";
      };

      scrapeConfigs = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [
          {
            job_name = "node-exporter";
            static_configs = [ { targets = [ "127.0.0.1:9100" ]; } ];
          }
        ];
        description = "Prometheus scrape configs passed to vmagent.";
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.victoriaMetricsRemoteWriteUrl != "") {
    services.vmagent = {
      enable = true;
      remoteWrite.url = cfg.victoriaMetricsRemoteWriteUrl;
      prometheusConfig = {
        global = {
          scrape_interval = cfg.vmagent.scrapeInterval;
        };
        scrape_configs = cfg.vmagent.scrapeConfigs;
      };
    };

    services.prometheus.exporters.node.enable = true;
  };
}

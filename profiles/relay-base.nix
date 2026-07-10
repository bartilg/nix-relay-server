{ pkgs, ... }:

{
  imports = [
    ../modules/docker.nix
    ../modules/containers
    ../modules/shell
    ../modules/monitoring
    ../modules/nvim/nvchad.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;
  services.resolved.enable = false;

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
  };

  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 10d";
    };

    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  time.timeZone = "UTC";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    btop
    fastfetch
    zsh
    tree
    nixfmt
    tcpdump
    ripgrep
    codex
    gh
  ];

  environment.variables.EDITOR = "nvim";
  environment.enableAllTerminfo = true;

  services.qemuGuest.enable = true;
  services.openssh.enable = true;

  services.homelabMonitoring = {
    enable = true;
    victoriaMetricsRemoteWriteUrl = "https://victoriametrics.local.ilghost.party/api/v1/write";
    victoriaLogsRemoteWriteUrl = "https://victorialogs.local.ilghost.party/insert/native";
  };

  networking.firewall = {
    enable = true;
    allowPing = true;
    checkReversePath = "loose";
    allowedTCPPorts = [
      53
      80
      443
    ];
    allowedUDPPorts = [ 53 ];
    trustedInterfaces = [
      "docker0"
      "br-proxy"
    ];
  };
}

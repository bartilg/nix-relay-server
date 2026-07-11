let
  settings = import ./settings.nix;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/relay-base.nix
    ../../users/users.nix
  ];

  networking.hostName = settings.hostName;

  services.homelabPihole.nebulaSync.enable = settings.piholeNebulaSyncLeader;

  networking.firewall = {
    trustedInterfaces = settings.firewall.trustedInterfaces;
  };

  system.autoUpgrade = {
    flake = "github:bartilg/nix-relay-server#${settings.hostName}";
    dates = settings.autoUpgradeDates;
  };
  system.stateVersion = "24.11";
}

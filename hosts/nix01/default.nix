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

  system.autoUpgrade.flake = "path:/etc/nixos#${settings.hostName}";
  system.stateVersion = "24.11";
}

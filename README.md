# NixOS Config

Reusable NixOS flake for DNS relay hosts.

## Layout

- `flake.nix` defines deployable hosts under `nixosConfigurations`.
- `hosts/<hostname>/default.nix` contains host-specific imports and overrides.
- `hosts/<hostname>/settings.nix` contains the values normally changed when cloning a relay.
- `hosts/<hostname>/hardware-configuration.nix` is generated per host with `nixos-generate-config`.
- `profiles/relay-base.nix` contains the shared DNS relay host template.
- `modules/` contains reusable service modules.
- `modules/containers/` contains systemd wrappers for Docker Compose stacks.
- `stacks/` contains repo-managed Docker Compose files and non-secret app config.
- `users/` contains system user definitions.
- `home/` contains standalone Home Manager configurations.

## Adding A Host

1. Create `hosts/<hostname>/default.nix`.
2. Create `hosts/<hostname>/settings.nix` with the hostname and host-specific firewall exceptions.
3. Copy or generate that machine's `hardware-configuration.nix` into `hosts/<hostname>/`.
4. Import `../../profiles/relay-base.nix`, `../../users/users.nix`, and any host-specific modules needed by that host.
5. Add a matching entry to `nixosConfigurations` in `flake.nix`.

Validate with:

```sh
nix flake check path:/etc/nixos
```

Build or switch a host with:

```sh
sudo nixos-rebuild switch --flake path:/etc/nixos#nix01
```

## Container State And Secrets

The compose files are managed in `stacks/`, but mutable application data and secrets live outside the repo:

- `/var/lib/homelab/pihole/pihole.env`
- `/var/lib/homelab/pihole/etc-pihole/`
- `/var/lib/homelab/pihole/etc-dnsmasq.d/`
- `/var/lib/homelab/traefik/traefik.env`
- `/var/lib/homelab/traefik/acme.json`

Use the matching `env.example` files in `stacks/` as templates. The stack services are skipped until their required env files exist.

Nebula Sync is kept as an optional compose override in `stacks/pihole/compose.nebula-sync.yaml`; the default relay stack does not require it.

The shared Docker network is created by Nix as `proxy` with the stable bridge interface `br-proxy`. If an older `proxy` network exists with a different bridge, the Nix-managed network unit recreates it.

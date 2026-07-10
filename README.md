# NixOS Config

Reusable NixOS flake for DNS relay hosts.

## Layout

- `flake.nix` defines deployable hosts under `nixosConfigurations`.
- `hosts/<hostname>/default.nix` contains host-specific imports and overrides.
- `hosts/<hostname>/settings.nix` contains the values normally changed when cloning a relay.
- `hosts/<hostname>/hardware-configuration.nix` is generated per host with `nixos-generate-config`.
- `profiles/relay-base.nix` contains the shared DNS relay host template.
- `modules/` contains reusable service modules.
- `modules/containers/` maps the Compose projects into systemd services.
- `stacks/` owns the Compose files, container env-file paths, volumes, and non-secret app config.
- `users/` contains system user definitions.
- `home/` contains standalone Home Manager configurations.

## Adding A Host

1. Create `hosts/<hostname>/default.nix`.
2. Create `hosts/<hostname>/settings.nix` with the hostname and host-specific firewall exceptions.
3. Copy or generate that machine's `hardware-configuration.nix` into `hosts/<hostname>/`.
4. Import `../../profiles/relay-base.nix`, `../../users/users.nix`, and any host-specific modules needed by that host.
5. Add a matching entry to `nixosConfigurations` in `flake.nix`.

Validate the flake with:

```sh
nix flake check
```

Build or switch a host with:

```sh
sudo nixos-rebuild switch --flake .#nix01
```

## Fresh Host Setup

Before the first rebuild, create the Compose-owned env files from the repository templates:

```sh
sudo install -d -m 700 /var/lib/homelab/pihole /var/lib/homelab/traefik
sudo install -m 600 stacks/pihole/env.example /var/lib/homelab/pihole/pihole.env
sudo install -m 600 stacks/traefik/env.example /var/lib/homelab/traefik/traefik.env
sudoedit /var/lib/homelab/pihole/pihole.env
sudoedit /var/lib/homelab/traefik/traefik.env
```

On the Pi-hole leader only, also configure Nebula Sync:

```sh
sudo install -m 600 stacks/pihole/nebula-sync.env.example /var/lib/homelab/pihole/nebula-sync.env
sudoedit /var/lib/homelab/pihole/nebula-sync.env
```

Then run the host rebuild. Nix enables Docker, creates the shared `proxy` network, and starts the Compose projects. Compose creates the application data directories and Traefik's `acme.json` as needed.

## Compose Lifecycle

The stack definitions remain ordinary Compose projects. Their top-level `compose.yaml` files load the runtime env file and include the service definitions; Nix does not create or populate env files.

The Nix systemd mapping runs `docker compose up --detach --remove-orphans --pull always --wait`. Changing a stack in this repository and rebuilding reloads that stack, pulls its declared images, recreates only containers whose image or configuration changed, and waits for them to become running or healthy. The same units start the projects after boot.

After changing a runtime env file, reconcile its project directly through the mapped unit:

```sh
sudo systemctl reload homelab-pihole.service
sudo systemctl reload homelab-traefik.service
```

Inspect deployment failures with `systemctl status` or `journalctl -u` for those units. Reconciliation errors are not suppressed.

## Dependency Updates

Renovate scans the Nix flake inputs and Docker Compose images and opens update pull requests. The configuration also enables periodic `flake.lock` maintenance.

Install the [Mend Renovate GitHub App](https://github.com/apps/renovate) for this repository to activate the scans. Renovate reads its repository settings from `renovate.json`.

## Container State And Secrets

The compose files are managed in `stacks/`, but mutable application data and secrets live outside the repo:

- `/var/lib/homelab/pihole/pihole.env`
- `/var/lib/homelab/pihole/etc-pihole/`
- `/var/lib/homelab/pihole/nebula-sync.env` on the leader
- `/var/lib/homelab/traefik/traefik.env`
- `/var/lib/homelab/traefik/acme.json`

Use the matching `env.example` files in `stacks/` as templates. Missing or invalid env files cause the corresponding Compose unit to fail visibly.

The Traefik route to the Pi-hole web UI is set per location with `PIHOLE_TRAEFIK_HOST` in `pihole.env` (defaults to `pihole.local.ilghost.party` if unset).

Nebula Sync follows a leader model: only the leader host runs it (`piholeNebulaSyncLeader = true` in that host's `settings.nix`, currently nix01) and pushes its Pi-hole config to the replicas listed in `/var/lib/homelab/pihole/nebula-sync.env`. Replica hosts set the flag to `false`, run only the plain Pi-hole stack, and receive the leader's changes.

The shared Docker network is created by Nix as `proxy` with the stable bridge interface `br-proxy`, which is trusted by the NixOS firewall. An existing incompatible `proxy` network causes the network unit to fail with cleanup instructions instead of disconnecting containers automatically.

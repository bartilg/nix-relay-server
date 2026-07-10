# NixOS Config

Reusable NixOS flake for DNS relay hosts.

## Layout

- `flake.nix` defines deployable hosts under `nixosConfigurations`.
- `hosts/<hostname>/default.nix` contains host-specific imports and overrides.
- `hosts/<hostname>/settings.nix` contains the values normally changed when cloning a relay.
- `hosts/<hostname>/hardware-configuration.nix` is generated per host with `nixos-generate-config`.
- `profiles/relay-base.nix` contains the shared DNS relay host template.
- `modules/` contains reusable service modules.
- `scripts/bootstrap.sh` creates the mutable Compose directories and env files.
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

Before the first rebuild, run the interactive bootstrap script:

```sh
sudo ./scripts/bootstrap.sh
```

It creates the required directories, prompts for the Pi-hole and Traefik settings, generates the dashboard password hash, and writes mode `0600` env files. It infers the Nebula Sync leader default from the current host settings; this can also be selected explicitly:

```sh
sudo ./scripts/bootstrap.sh --leader
sudo ./scripts/bootstrap.sh --replica
```

Existing env files are preserved. Use `--force` to replace selected files after confirmation.

Then run the host rebuild. Nix enables Docker and starts the Compose projects. Each reconciliation ensures the shared `proxy` network exists before Compose runs. Compose creates the application data directories and Traefik's `acme.json` as needed.

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

The Nix-to-Compose mapping creates the shared Docker network as `proxy` with the stable bridge interface `br-proxy`, which is trusted by the NixOS firewall. Every stack reconciliation recreates a missing network and rejects an existing network that uses an incompatible bridge.

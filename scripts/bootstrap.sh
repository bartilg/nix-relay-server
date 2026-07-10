#!/usr/bin/env bash

set -euo pipefail

state_root="${HOMELAB_STATE_DIR:-/var/lib/homelab}"
force=false
leader=""
original_args=("$@")

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [--leader|--replica] [--force]

Create the directories and Compose env files required by the relay stacks.

  --leader   Configure Nebula Sync on this host
  --replica  Do not configure Nebula Sync on this host
  --force    Replace existing env files after confirmation
EOF
}

while (( $# > 0 )); do
  case "$1" in
    --leader)
      leader=true
      ;;
    --replica)
      leader=false
      ;;
    --force)
      force=true
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [[ "$state_root" == "/var/lib/homelab" && $EUID -ne 0 ]]; then
  exec sudo -- "$0" "${original_args[@]}"
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
host_name="$(</proc/sys/kernel/hostname)"
host_name="${host_name%%.*}"

prompt() {
  local variable=$1 label=$2 default=${3-} secret=${4-false} input

  if [[ "$secret" == true ]]; then
    read -r -s -p "$label: " input
    printf '\n'
  elif [[ -n "$default" ]]; then
    read -r -p "$label [$default]: " input
  else
    read -r -p "$label: " input
  fi

  input=${input:-$default}
  printf -v "$variable" '%s' "$input"
}

prompt_required() {
  local variable=$1 label=$2 secret=${3-false}
  local value=""

  while [[ -z "$value" ]]; do
    prompt value "$label" "" "$secret"
    [[ -n "$value" ]] || echo "A value is required." >&2
  done
  printf -v "$variable" '%s' "$value"
}

confirm() {
  local label=$1 default=${2-false} answer suffix
  if [[ "$default" == true ]]; then
    suffix="Y/n"
  else
    suffix="y/N"
  fi

  read -r -p "$label [$suffix]: " answer
  case "${answer:-}" in
    y | Y | yes | YES) return 0 ;;
    n | N | no | NO) return 1 ;;
    "") [[ "$default" == true ]] ;;
    *) return 1 ;;
  esac
}

dotenv_quote() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//\'/\\\'}
  printf "'%s'" "$value"
}

write_env() {
  local destination=$1
  shift
  local temporary
  temporary="$(mktemp "${destination}.tmp.XXXXXX")"
  trap 'rm -f "$temporary"' EXIT

  while (( $# > 0 )); do
    printf '%s=' "$1" >>"$temporary"
    dotenv_quote "$2" >>"$temporary"
    printf '\n' >>"$temporary"
    shift 2
  done

  chmod 0600 "$temporary"
  mv -f "$temporary" "$destination"
  trap - EXIT
  echo "Wrote $destination"
}

configure_file() {
  local path=$1
  [[ ! -e "$path" ]] && return 0
  [[ "$force" == true ]] && confirm "$path exists; replace it?" false
}

install -d -m 0750 "$state_root"
install -d -m 0700 "$state_root/pihole" "$state_root/traefik"
install -d -m 0750 "$state_root/pihole/etc-pihole"

pihole_env="$state_root/pihole/pihole.env"
if configure_file "$pihole_env"; then
  default_pihole_host="${host_name}-pihole.local.ilghost.party"
  [[ "$host_name" == "nix01" ]] && default_pihole_host="pihole.local.ilghost.party"

  prompt timezone "Pi-hole timezone" "America/Los_Angeles"
  prompt_required pihole_password "Pi-hole web password" true
  prompt pihole_host "Pi-hole DNS hostname" "$default_pihole_host"

  write_env "$pihole_env" \
    TZ "$timezone" \
    PIHOLE_WEBPASSWORD "$pihole_password" \
    PIHOLE_TRAEFIK_HOST "$pihole_host"
else
  echo "Keeping $pihole_env"
fi

traefik_env="$state_root/traefik/traefik.env"
if configure_file "$traefik_env"; then
  prompt_required cloudflare_token "Cloudflare DNS API token" true
  prompt dashboard_user "Traefik dashboard username" "admin"

  if command -v openssl >/dev/null 2>&1; then
    prompt_required dashboard_password "Traefik dashboard password" true
    dashboard_hash="$(printf '%s\n' "$dashboard_password" | openssl passwd -apr1 -stdin)"
    dashboard_credentials="${dashboard_user}:${dashboard_hash}"
  else
    prompt_required dashboard_credentials \
      "Traefik dashboard credentials (username:htpasswd-hash)" true
  fi

  write_env "$traefik_env" \
    CF_DNS_API_TOKEN "$cloudflare_token" \
    TRAEFIK_DASHBOARD_CREDENTIALS "$dashboard_credentials"
else
  echo "Keeping $traefik_env"
fi

if [[ -z "$leader" ]]; then
  leader=false
  settings_file="$repo_root/hosts/$host_name/settings.nix"
  if [[ -f "$settings_file" ]] && grep -Eq 'piholeNebulaSyncLeader[[:space:]]*=[[:space:]]*true' "$settings_file"; then
    leader=true
  fi
  if confirm "Configure this host as the Nebula Sync leader?" "$leader"; then
    leader=true
  else
    leader=false
  fi
fi

nebula_env="$state_root/pihole/nebula-sync.env"
if [[ "$leader" == true ]] && configure_file "$nebula_env"; then
  prompt primary_url "Primary Pi-hole URL" "http://pihole"
  prompt_required primary_password "Primary Pi-hole API password" true
  prompt_required replicas "Replica targets (comma-separated URL|password values)" true
  prompt sync_cron "Nebula Sync cron schedule" "*/10 * * * *"
  prompt_required sync_web_password "Nebula Sync web password" true

  full_sync=false
  confirm "Enable full sync?" false && full_sync=true
  run_gravity=false
  confirm "Run gravity after sync?" false && run_gravity=true

  write_env "$nebula_env" \
    PRIMARY "${primary_url}|${primary_password}" \
    REPLICAS "$replicas" \
    FULL_SYNC "$full_sync" \
    RUN_GRAVITY "$run_gravity" \
    CRON "$sync_cron" \
    SYNC_CONFIG_DNS "true" \
    WEBPASSWORD "$sync_web_password"
elif [[ "$leader" == true ]]; then
  echo "Keeping $nebula_env"
fi

cat <<EOF

Bootstrap complete. Apply the configuration with:
  sudo nixos-rebuild switch --flake .#$host_name
EOF

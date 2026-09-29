#!/usr/bin/env bash
# Bootstrap Nix + Home Manager package profile on a fresh Linux machine.
#
# Usage:
#   ./scripts/setup-nix.sh [minimal|default|security]
#
# Installs Nix (Determinate installer), deploys the chosen HM package
# profile from nix/flake.nix, and writes nix/machine.nix when the local
# username differs from the default. Idempotent — safe to re-run.
#
# Root requirements: /nix must be created at the filesystem root, so
# either sudo access or root is mandatory. Without it the script aborts.

set -euo pipefail

# --- Config -----------------------------------------------------------------

HM_FLAKE_REF="github:nix-community/home-manager"
VALID_PROFILES="minimal default security"

# --- Helpers ----------------------------------------------------------------

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==> %s\033[0m\n' "$*"; }
die() {
  printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2
  exit 1
}

# --- Args & environment ------------------------------------------------------

PROFILE="${1:-default}"
case "$PROFILE" in
minimal | default | security) ;;
*) die "Unknown profile '$PROFILE'. Valid profiles: $VALID_PROFILES" ;;
esac

OS="$(uname -s)"
[ "$OS" = "Linux" ] || die "This script targets Linux (got: $OS). On macOS use the Nix install in docs/setup.md."

ARCH="$(uname -m)"
case "$ARCH" in
x86_64 | aarch64) ;;
*) die "Unsupported architecture: $ARCH" ;;
esac

# Repo root = parent of this script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
[ -f "$REPO_ROOT/nix/flake.nix" ] || die "Repo layout mismatch: nix/flake.nix not found under $REPO_ROOT"

CURRENT_USER="${USER:-$(id -un)}"
if [ "$(id -u)" -eq 0 ]; then
  HAVE_ROOT=1
elif command -v sudo >/dev/null 2>&1; then
  HAVE_ROOT=1
  sudo -v 2>/dev/null || die "sudo exists but requires a password prompt that failed. Run 'sudo -v' first, then re-run."
else
  HAVE_ROOT=0
fi

# --- Install Nix --------------------------------------------------------------

if command -v nix >/dev/null 2>&1; then
  info "Nix already installed: $(nix --version)"
else
  if [ "$HAVE_ROOT" -ne 1 ]; then
    die "No root access found. Nix requires /nix at the filesystem root, which needs root.

Options:
  1. Ask the admin to run this script once with sudo, or
  2. Use nix-portable (rootless, proot-based, unofficial): https://github.com/nix-community/nix-portable"
  fi

  INSTALLER_URL="https://install.determinate.systems/nix"
  INSTALL_ARGS=(install --no-confirm)

  if [ -d /run/systemd/system ]; then
    info "Installing Nix (Determinate, multi-user with systemd)..."
  else
    info "Installing Nix (Determinate, single-user, no init daemon)..."
    INSTALL_ARGS+=(--init none)
  fi

  curl --proto '=https' --tlsv1.2 -sSf -L "$INSTALLER_URL" |
    sh -s -- "${INSTALL_ARGS[@]}"

  # Enable flakes for non-Determinate leftovers / safety net.
  # User-level nix.conf merges with system settings, no root needed.
  NIX_CONF="$HOME/.config/nix/nix.conf"
  if ! grep -q 'experimental-features' "$NIX_CONF" 2>/dev/null; then
    mkdir -p "$HOME/.config/nix"
    printf 'experimental-features = nix-command flakes\n' >>"$NIX_CONF"
    info "Enabled nix-command + flakes in $NIX_CONF"
  fi
fi

# --- Source Nix environment into this shell -----------------------------------

set +u
for PROFILE_SCRIPT in \
  /etc/profile.d/nix-daemon.sh \
  /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh \
  /nix/var/nix/profiles/default/etc/profile.d/nix.sh \
  "$HOME/.nix-profile/etc/profile.d/nix.sh"; do
  if [ -f "$PROFILE_SCRIPT" ]; then
    # shellcheck disable=SC1090
    . "$PROFILE_SCRIPT"
    break
  fi
done
set -u

command -v nix >/dev/null 2>&1 ||
  die "Nix installed but not available in this shell. Open a new shell and re-run this script."

# --- Deploy Home Manager profile ------------------------------------------------

# The flake resolves username + platform from the environment (getEnv USER,
# currentSystem), so Linux deploys must evaluate with --impure.
FLAKE="$REPO_ROOT/nix#${CURRENT_USER}-${PROFILE}"

info "Building profile '$PROFILE' (dry run)..."
nix build --impure "$FLAKE.activationPackage" --dry-run --no-link

info "Deploying profile '$PROFILE' via Home Manager..."
nix run "$HM_FLAKE_REF" -- switch --impure --flake "$FLAKE" -b backup

# --- Done -----------------------------------------------------------------------

GREEN=$'\033[1;32m'
RESET=$'\033[0m'

cat <<EOF

${GREEN}Done.${RESET} Packages from profile '$PROFILE' are active for $CURRENT_USER.

Next steps (config deployment is separate — chezmoi):
  just dot init     # once: prompts for git name/email
  just dot apply    # deploy configs

PATH is picked up automatically by the deployed nushell/bash configs
(~/.nix-profile/bin is prepended). Open a new shell to use them.

Useful commands (from the repo root):
  just pack deploy $PROFILE   # redeploy after editing nix/profiles/$PROFILE.nix
  just pack rollback          # roll back to previous generation
  just pack gc                # garbage collect old generations
EOF

# === Nix Commands ===

# Local username (flake profile keys are "<username>-<profile>").
# Linux deploys evaluate with --impure so the flake picks up USER for
# username + platform; macOS pure eval falls back to variables.nix.
username := env_var_or_default('USER', 'scc')

# Platform decides the deployment mechanism; the profile argument decides
# the package set. On macOS the profile argument is ignored — nix-darwin
# manages the whole system (packages + settings + services) via the
# "<username>-mac" configuration. `mac` is accepted as a no-op alias.

_default:
    @just --unsorted --list pack

# Dry-build: list build results
[group('build')]
dry profile='default':
    {{ if os() == "macos" { 'nix build "./#darwinConfigurations.' + username + '-mac.system" --dry-run --no-link' } else { 'nix build --impure "./#homeConfigurations.' + username + '-' + profile + '.activationPackage" --dry-run --no-link' } }}

# Build: build, no switch
[group('build')]
build profile='default':
    {{ if os() == "macos" { 'sudo darwin-rebuild build --flake "./#' + username + '-mac"' } else { 'nix run home-manager -- build --impure --flake "./#' + username + '-' + profile + '"' } }}

# Deploy: build and switch
[group('deploy')]
deploy profile='default':
    {{ if os() == "macos" { 'sudo darwin-rebuild switch --flake "./#' + username + '-mac"' } else { 'nix run home-manager -- switch --impure --flake "./#' + username + '-' + profile + '" -b backup' } }}

# Rollback to previous generation
[group('deploy')]
rollback:
    {{ if os() == "macos" { 'sudo darwin-rebuild rollback' } else { 'nix run home-manager -- rollback' } }}

# List generations
[group('deploy')]
generations:
    {{ if os() == "macos" { 'darwin-rebuild --list-generations' } else { 'nix run home-manager -- generations' } }}

# Update flake inputs
[group('maintenance')]
update:
    nix flake update --flake .

# Garbage collect old generations (keep last N days)
[group('maintenance')]
gc keep='5':
    nix-collect-garbage --delete-older-than {{ keep }}d

# Evaluate a Nix expression
[group('dev')]
eval expr:
    nix eval --impure --expr '{{ expr }}'

# Check flake for errors
[group('dev')]
check:
    nix flake check .

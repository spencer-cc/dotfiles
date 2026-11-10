# Package management via Homebrew (Brewfiles: core, dev, desktop, security)
# NOTE: recipes run with cwd = this module's dir (brew/), so relative paths work.

_default:
    @just --unsorted --list brew

_brewfile group:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{ group }}" in
        core)     echo "./Brewfile" ;;
        dev)      echo "./Brewfile.dev" ;;
        desktop)  echo "./Brewfile.desktop" ;;
        security) echo "./Brewfile.security" ;;
        all)      echo "./Brewfile ./Brewfile.dev ./Brewfile.desktop ./Brewfile.security" ;;
        *) echo "unknown group '{{ group }}' (core|dev|desktop|security|all)" >&2; exit 1 ;;
    esac

# Run a brew bundle subcommand (install|update|list) over one group or all
_bundle verb group="all":
    #!/usr/bin/env bash
    set -euo pipefail
    for f in $(just brew _brewfile {{ group }}); do
        echo "==> brew bundle {{ verb }} --file=$f"
        brew bundle {{ verb }} --file="$f"
    done

# Install packages: group = core|dev|desktop|security|all
[group('pack')]
install group="all":
    @just brew _bundle install {{ group }}

# Update brew packages (all groups by default, or one)
[group('pack')]
update group="all":
    @just brew _bundle update {{ group }}

# List packages tracked by the Brewfiles
[group('pack')]
list:
    @just brew _bundle list all

# Show missing packages for each Brewfile (all groups by default, or one)
# Own body (not _bundle): `brew bundle check` exits nonzero on missing packages,
# which must not abort the remaining files.
[group('pack')]
check group="all":
    #!/usr/bin/env bash
    set -euo pipefail
    for f in $(just brew _brewfile {{ group }}); do
        echo "==> $f"
        brew bundle check --file="$f" || true
    done

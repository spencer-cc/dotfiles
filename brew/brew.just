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
        *) echo "unknown group '{{ group }}' (core|dev|desktop|security)" >&2; exit 1 ;;
    esac

# Install packages: group = core|dev|desktop|security|all
[group('pack')]
install group="all":
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "{{ group }}" = "all" ]; then
        for f in ./Brewfile ./Brewfile.dev ./Brewfile.desktop ./Brewfile.security; do
            echo "==> brew bundle install --file=$f"
            brew bundle install --file="$f"
        done
    else
        f="$(just brew _brewfile {{ group }})"
        echo "==> brew bundle install --file=$f"
        brew bundle install --file="$f"
    fi

# Update brew packages (all groups by default, or one)
[group('pack')]
update group="all":
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "{{ group }}" = "all" ]; then
        for f in ./Brewfile ./Brewfile.dev ./Brewfile.desktop ./Brewfile.security; do
            echo "==> brew bundle update --file=$f"
            brew bundle update --file="$f"
        done
    else
        f="$(just brew _brewfile {{ group }})"
        echo "==> brew bundle update --file=$f"
        brew bundle update --file="$f"
    fi

# List packages tracked by the Brewfiles
[group('pack')]
list:
    #!/usr/bin/env bash
    set -euo pipefail
    for f in ./Brewfile ./Brewfile.dev ./Brewfile.desktop ./Brewfile.security; do
        echo "==> $f"
        brew bundle list --file="$f"
    done

# Show missing packages for each Brewfile (all groups by default, or one)
[group('pack')]
check group="all":
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "{{ group }}" = "all" ]; then
        files="./Brewfile ./Brewfile.dev ./Brewfile.desktop ./Brewfile.security"
    else
        files="$(just brew _brewfile {{ group }})"
    fi
    for f in $files; do
        echo "==> $f"
        brew bundle check --file="$f" || true
    done

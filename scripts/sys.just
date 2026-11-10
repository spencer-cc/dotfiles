# System setup tasks (macOS)

_default:
    @just --unsorted --list sys

# Enable Touch ID for sudo (idempotent; writes /etc/pam.d/sudo_local)
[group('sys')]
touchid:
    #!/usr/bin/env bash
    set -euo pipefail
    if grep -q pam_tid.so /etc/pam.d/sudo_local 2>/dev/null; then
        echo "Touch ID for sudo already enabled"
        exit 0
    fi
    echo 'auth       sufficient     pam_tid.so' | sudo tee -a /etc/pam.d/sudo_local >/dev/null
    echo "Touch ID for sudo enabled"

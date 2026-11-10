_default:
    @just --unsorted --list

# Dotfiles: deploy configs via chezmoi
[group('dot')]
mod dot 'configs/dot.just'

# Brew: package management (Brewfiles: core, dev, desktop, security)
[group('pack')]
mod brew 'brew/brew.just'

# System setup tasks (Touch ID sudo, etc.)
[group('sys')]
mod sys 'scripts/sys.just'

# Neovim configuration tasks
[group('tools')]
mod nvim 'configs/dot_config/nvim/.nvim.just'

# Sketchybar configuration tasks
[group('tools')]
mod skbar 'configs/dot_config/sketchybar/.sketchybar.just'

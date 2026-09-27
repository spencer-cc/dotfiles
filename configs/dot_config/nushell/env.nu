# ----- Env Variables -----

# Nix profiles — prepend so Nix-managed packages take priority
# Both paths included: standalone HM uses ~/.nix-profile/bin,
# nix-darwin embedded HM uses ~/.local/state/nix/profiles/home-manager/home-path/bin
$env.PATH = ($env.PATH
  | prepend $"($env.home)/.local/state/nix/profiles/home-manager/home-path/bin"
  | prepend $"($env.home)/.nix-profile/bin")

$env.LESS = "-R -f"
$env.LESSKEYIN = $"($env.home)/.config/lesskey"

if not (which bat | is-empty) {
  $env.PAGER = "bat"
  # bat as man pager: strip SGR escapes from man's output so bat can re-highlight with `man` syntax
  $env.MANPAGER = "sh -c 'sed \"s/\\x1b\\[[0-9;]*m//g\" | bat -l man -p'"
}

$env.XDG_CONFIG_HOME = $"($env.home)/.config"
$env.XDG_CACHE_HOME = $"($env.home)/.cache"
$env.nu_config_dir = $"($env.XDG_CONFIG_HOME)"
$env.nu_module_dir = $"($env.nu_config_dir)/nushell/modules"
$env.nu_confs_dir = $"($env.nu_config_dir)/nushell/confs"
$env.NU_LIB_DIRS ++= [$env.nu_module_dir $env.nu_confs_dir]

if not (which nvim | is-empty) {
  $env.config.buffer_editor = "nvim"
  $env.EDITOR = "nvim"
  $env.VISUAL = "nvim"
}

$env.ZELLIJ_CONFIG_DIR = $"($env.XDG_CONFIG_HOME)/zellij"

$env.OPENCODE_ENABLE_EXA = 1

# Restore COLORTERM over SSH (Ghostty sets this locally but it's not forwarded)
if ($env.TERM | str contains "ghostty") and ($env.COLORTERM? | is-empty) {
  $env.COLORTERM = "truecolor"
}

# ----- External Configs -----
# Shell tool integrations generated at startup (cache file approach)
# aggregator.nu sources these from ~/.cache/nushell/

mkdir ~/.cache/nushell

if not (which starship | is-empty) {
  starship init nu | save -f ~/.cache/nushell/starship.nu
}
if not (which zoxide | is-empty) {
  zoxide init nushell --no-cmd | save -f ~/.cache/nushell/zoxide.nu
}
if not (which carapace | is-empty) {
  carapace _carapace nushell | save -f ~/.cache/nushell/carapace.nu
}
if not (which just | is-empty) {
  $env.JUST_COMPLETE_ALIASES = 'true'
  $env.JUST_COMMAND_COLOR = 'black'
  $env.JUST_EXPLAIN = 'true'
  $env.JUST_UNSORTED = 'true'
  just --completions nushell | save -f ~/.cache/nushell/just.nu
}

$env.SHELL = "/bin/bash" # set shell to bash for tools that need it

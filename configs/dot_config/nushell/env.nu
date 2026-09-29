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
# Shell tool integrations generated at startup
# aggregator.nu sources these from ~/.cache/nushell/

let cache_dir = $env.XDG_CACHE_HOME | path join "nushell"
mkdir $cache_dir

let tool_inits = [
  {
    name: starship
    file: starship.nu
    gen: {|| starship init nu }
  }
  {
    name: zoxide
    file: zoxide.nu
    gen: {|| zoxide init nushell --no-cmd }
  }
  {
    name: carapace
    file: carapace.nu
    gen: {|| carapace _carapace nushell }
  }
  {
    name: just
    file: just.nu
    gen: {|| just --completions nushell }
    env: {
      JUST_COMPLETE_ALIASES: 'true'
      JUST_COMMAND_COLOR: 'black'
      JUST_EXPLAIN: 'true'
      JUST_UNSORTED: 'true'
    }
  }
]

for t in $tool_inits {
  let path = $cache_dir | path join $t.file
  let bin = which $t.name | get --optional 0.path
  let needs_gen = (if $bin == null {
    false # missing tool -> write stub below
  } else if not ($path | path exists) {
    true
  } else {
    (ls $path | get 0.modified) < (ls $bin | get 0.modified)
  })
  if $bin != null {
    for e in ($t.env? | default {} | transpose key value) {
      $env = ($env | upsert $e.key $e.value)
    }
  }
  if $needs_gen {
    try {
      do $t.gen | save -f $path
    } catch {
      '' | save -f $path
    }
  } else if not ($path | path exists) {
    '' | save -f $path # stub for missing tool
  }
}

$env.SHELL = "/bin/bash" # set shell to bash for tools that need it

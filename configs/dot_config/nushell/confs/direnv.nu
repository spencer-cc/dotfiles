# ----- direnv integration (https://www.nushell.sh/cookbook/direnv.html) -----
# Loads/unloads .envrc environments on directory change.
# Requires the direnv binary (home-manager: programs.direnv) and nix-direnv
# for `use flake` support in .envrc files.

use std/config *

# Initialize the PWD hook as an empty list if it doesn't exist
$env.config.hooks.env_change.PWD = $env.config.hooks.env_change.PWD? | default []

$env.config.hooks.env_change.PWD ++= [{||
  if (which direnv | is-empty) {
    # If direnv isn't installed, do nothing
    return
  }

  direnv export json | from json | default {} | update cells --columns [ PATH ] {
    # If direnv changes the PATH, it will become a string and we need to re-convert it to a list
    do (env-conversions).path.from_string $in
  } | load-env
}]

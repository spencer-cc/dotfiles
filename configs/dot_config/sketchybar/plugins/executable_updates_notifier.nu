#!/usr/bin/env nu -n

def main [name: string, animation_type: string, animation_speed: string] {
  use ../core/icons.nu *

  # takes multiple seconds
  # Absolute path: launchd services don't have /usr/sbin on PATH.
  let result = do { ^/usr/sbin/softwareupdate -l } | complete

  let has_updates = if $result.exit_code == 0 {

    # Available updates are listed as '* Label: ...' lines; the
    # "No new software available." output contains none.
    ($result.stdout
      | lines
      | where {|line| $line | str starts-with "* Label:" }
      | is-not-empty)
  } else {
    false
  }

  sketchybar ...[
    --animate
    $animation_type
    $animation_speed
    --set
    $name
    drawing=($has_updates)
  ]
}

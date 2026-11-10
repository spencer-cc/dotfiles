#!/usr/bin/env nu -n

def main [name: string, animation_type: string, animation_speed: string] {
  use ../core/icons.nu *
  let percentage = (
    ^pmset -g batt
    | parse -r '\s+(?<percent>\d+)%'
    | get percent
    | into int
  ).0
  let charging = (^pmset -g batt | str contains 'AC Power')
  if $percentage == null { return }
  let icon = if $charging { icons widget battery_charging } else {
    if $percentage > 75 {
      icons widget battery_full
    } else if $percentage > 50 {
      icons widget battery_medium
    } else if $percentage > 25 {
      icons widget battery_low
    } else {
      icons widget battery_empty
    }
  }
  sketchybar ...[
    --animate
    $animation_type
    $animation_speed
    --set
    $name
    icon=($icon)
    label=($"($percentage)%")
  ]
}

#!/usr/bin/env nu -n

def main [
  name: string
  animation_type: string
  animation_speed: string
  threshold: string
] {
  let time_since_boot = sys host | get uptime
  let threshold = $threshold | into duration
  let toggle = if $time_since_boot >= $threshold { "on" } else { "off" }
  sketchybar ...[
    --animate
    $animation_type
    $animation_speed
    --set
    $name
    drawing=($toggle)
  ]
}

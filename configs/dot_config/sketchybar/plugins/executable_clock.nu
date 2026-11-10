#!/usr/bin/env nu -n

def main [
  name: string
  animation_type: string
  animation_speed: string
  format: string
] {
  sketchybar ...[
    --animate
    $animation_type
    $animation_speed
    --set
    $name
    label=(date now | format date ($format))
  ]
}

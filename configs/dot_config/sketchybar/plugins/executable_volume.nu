#!/usr/bin/env nu -n

def main [
  name: string
  animation_type: string
  animation_speed: string
  right_pad: string
] {
  use ../core/icons.nu *
  let volume = (osascript -e "output volume of (get volume settings)")
  let icon = if $volume == "missing value" {
    icons widget volume_mute
  } else {
    let volume = $volume | into int
    if $volume > 50 {
      icons widget volume_high
    } else if $volume > 0 {
      icons widget volume_low
    } else {
      icons widget volume_mute
    }
  }
  let label = if $volume == "missing value" {
    ("--")
  } else {
    if ($volume | into int) > 0 { $"($volume)%" } else { ("") }
  }
  let padding = if $icon == (icons widget volume_mute) { 0 } else { $right_pad }
  sketchybar ...[
    --animate
    $animation_type
    $animation_speed
    --set
    $name
    icon=($icon)
    label=($label)
    label.padding_right=($padding)
  ]
}

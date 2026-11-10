#!/usr/bin/env nu -n

use ~/.config/nushell/modules/dexcom.nu

def main [name: string, animation_type: string, animation_speed: string] {
  let result = try {
    let data = dexcom
    if ($data | is-empty) { "--" } else {
      let reading = $data | first
      $"($reading.Value) ($reading.Arrow)"
    }
  } catch { "--" }

  sketchybar ...[
    --animate
    $animation_type
    $animation_speed
    --set
    $name
    label=($result)
  ]
}

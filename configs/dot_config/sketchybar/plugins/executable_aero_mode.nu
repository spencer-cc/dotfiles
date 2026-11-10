#!/usr/bin/env nu -n

use ../core/aerospace.nu aero

def get_mode [] {
  aero [list-windows --focused --format '%{window-parent-container-layout}']
  | str replace --regex "._" ""
  | match $in {
    accordion => "wm_accordion"
    tiles => "wm_tiling"
    floating => "wm_floating"
    _ => "wm_tiling"
  }
}

def main [name: string, animation_type: string, animation_speed: string] {
  use ../core/icons.nu *
  sketchybar ...[
    --animate
    $animation_speed
    $animation_type
    --set
    $name
    icon=(icons widget (get_mode))
  ]
}

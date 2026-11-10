#!/usr/bin/env nu -n

def main [] {
  let script = [
    ($env.CONFIG_DIR)/plugins/volume.nu
    $env.name
    $env.animation_type
    $env.animation_speed
    $env.right_pad
  ] | str join " "
  sketchybar ...[
    --add
    item
    $env.name
    $env.side
    --animate
    $env.animation_type
    $env.animation_speed
    --set
    $env.name
    label.color=($env.color)
    icon.color=($env.color)
    icon.font=($env.icon_font)
    script=($script)
    --subscribe
    $env.name
    volume_change
    system_woke
  ]
}

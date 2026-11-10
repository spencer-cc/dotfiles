#!/usr/bin/env nu -n

def main [] {
  use ../core/icons.nu *
  let icon = icons widget clock
  let script = [
    ($env.CONFIG_DIR)/plugins/clock.nu
    $env.name
    $env.animation_type
    $env.animation_speed
    $"\"($env.format)\""
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
    icon.color=($env.color)
    label.color=($env.color)
    icon=($icon)
    script=($script)
    update_freq=($env.update_freq)
    --subscribe
    $env.name
    system_woke
  ]
}

#!/usr/bin/env nu -n

def main [] {
  use ../core/icons.nu *
  let icon = icons widget mail
  let script = [
    ($env.CONFIG_DIR)/plugins/mail.nu
    $env.name
    $env.animation_type
    $env.animation_speed
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
    label=--
    script=($script)
    update_freq=($env.update_freq)
  ]
}

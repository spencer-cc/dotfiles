#!/usr/bin/env nu -n

def main [] {
  let script = [
    ($env.CONFIG_DIR)/plugins/battery.nu
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
    icon.font=($env.icon_font)
    icon.color=($env.color)
    label.color=($env.color)
    script=($script)
    update_freq=($env.update_freq)
    --subscribe
    $env.name
    system_woke
    power_source_change
  ]
}

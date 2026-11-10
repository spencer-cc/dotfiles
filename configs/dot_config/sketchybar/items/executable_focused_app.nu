#!/usr/bin/env nu -n

def main [] {
  let script = [
    ($env.CONFIG_DIR)/plugins/focused_app.nu
    $env.name
    $env.animation_type
    $env.animation_speed
  ] | str join " "
  sketchybar ...[
    --animate
    ($env.animation_type)
    ($env.animation_speed)
    --add
    item
    ($env.name)
    ($env.side)
    --set
    ($env.name)
    script=($script)
    icon.color=($env.color)
    icon.font=($env.icon_font)
    label.color=($env.color)
    --subscribe
    $env.name
    front_app_switched
    system_woke
  ]
}

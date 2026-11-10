#!/usr/bin/env nu -n

def main [] {
  let script = [
    ($env.CONFIG_DIR)/plugins/aero_mode.nu
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
    label.padding_right=0
    label.padding_left=0
    script=($script)
    update_freq=($env.update_freq)
    --subscribe
    $env.name
    aerospace_workspace_change
    system_woke
    front_app_switched
  ]
}

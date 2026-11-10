#!/usr/bin/env nu -n

def main [] {
  use ../core/icons.nu *
  let icon = icons app "Dexcom"
  let script = [
    ($env.CONFIG_DIR)/plugins/dexcom.nu
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
    icon=($icon)
    icon.color=($env.color)
    icon.font=($env.icon_font)
    label.color=($env.color)
    script=($script)
    click_script=($script)
    label=--
    update_freq=($env.update_freq)
  ]
}

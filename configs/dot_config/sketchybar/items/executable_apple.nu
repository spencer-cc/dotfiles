#!/usr/bin/env nu -n

def main [] {
  sketchybar ...[
    --animate
    ($env.animation_type)
    ($env.animation_speed)
    --add
    item
    $env.name
    $env.side
    --set
    $env.name
    icon.color=($env.color)
    icon=󰀵
    label.padding_right=0
    label.padding_left=0
    --subscribe
    $env.name
    system_woke
  ]
}

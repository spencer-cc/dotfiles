#!/usr/bin/env nu -n

use ../core/aerospace.nu aero

def workspaces [] {
  aero [list-workspaces --all] | lines
}

def main [] {
  sketchybar ...[
    --add
    item
    aerospace_left
    $env.side
    --set
    aerospace_left
    label.padding_right=($env.outer_pad)
    label.padding_left=0
    icon.padding_left=0
    icon.padding_right=0
  ]

  workspaces
  | each {|workspace|
    let name = $"aerospace_($workspace)"
    let script = [
      ($env.CONFIG_DIR)/plugins/aerospace.nu
      ($name)
      $workspace
      $env.color_focused
      $env.color_full
      $env.color_empty
    ] | str join " "
    sketchybar ...[
      --animate $env.animation_type $env.animation_speed
      --add item $name $env.side
      --set $name
      label=($workspace)
      label.color=($env.color_empty)
      icon.padding_right=0
      icon.padding_left=0
      label.padding_left=($env.label_pad)
      label.padding_right=($env.label_pad)
      update_freq=($env.update_freq)
      script=($script)
      click_script=([aerospace workspace ($workspace)] | str join " ")
      --subscribe $name aerospace_workspace_change system_woke # front_app_switched
    ]
  }
  | ignore

  sketchybar ...[
    --add
    item
    aerospace_right
    $env.side
    --set
    aerospace_right
    label.padding_left=0
    label.padding_right=($env.outer_pad)
    icon.padding_left=0
    icon.padding_right=0
  ]
}

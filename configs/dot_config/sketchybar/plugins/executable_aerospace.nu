#!/usr/bin/env nu -n

use ../core/aerospace.nu aero

def workspace_status [workspace: string] {
  let focused = aero [list-workspaces --focused]
  if $workspace == $focused {
    return "active"
  } else {
    let windows = aero [list-windows --workspace $workspace] | lines | length
    if $windows > 0 {
      return "full"
    } else {
      return "empty"
    }
  }
}

def main [
  name: string
  workspace: string
  active_color: string
  full_color: string
  empty_color: string
] {
  let color = match (workspace_status $workspace) {
    active => $active_color
    full => $full_color
    empty => $empty_color
    _ => "#000000"
  }
  sketchybar ...[
    --set
    $name
    label.color=($color)
  ]
}

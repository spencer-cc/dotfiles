#!/usr/bin/env nu -n

def get_focus [] {
  use ../core/icons.nu *
  # getfocus requires Full Disk Access to read ~/Library/DoNotDisturb/DB/
  # Without it, the binary exits 1 and writes to stderr. The try/catch
  # prevents the script from aborting, and the "error" match arm shows
  # a warning triangle so the user knows something is wrong.
  let mode = try { ^($env.FILE_PWD | path join "getfocus") } catch { "error" }
  return (match ($mode) {
    "Do Not Disturb" => {
      {
        icon: (icons widget "focus_dnd")
        color: "0xFF6D7CFF"
        draw: "on"
      }
    }
    "Sleep" => {
      {
        icon: (icons widget "focus_sleep")
        color: "0xFF14B6A4"
        draw: "on"
      }
    }
    "Reduce Interruptions" => {
      {
        icon: (icons widget "focus_reduce")
        color: "0xFFDB34F2"
        draw: "on"
      }
    }
    "error" => {
      {
        icon: (icons widget "warning")
        color: "0xFFf0d57c"
        draw: "on"
      }
    }
    "None" => {
      {
        icon: ""
        color: "0xFF6D7CFF"
        draw: "off"
      }
    }
    $focus => {
      print $"Unknown focus mode: '($focus)'"
      {
        icon: ""
        color: "0xFF6D7CFF"
        draw: "off"
      }
    }
  })
}

def main [name: string, animation_type: string, animation_speed: string] {
  let focus = get_focus
  sketchybar ...[
    --animate
    $animation_type
    $animation_speed
    --set
    $name
    icon=($focus.icon)
    icon.color=($focus.color)
    drawing=($focus.draw)
  ]
}

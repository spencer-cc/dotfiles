#!/usr/bin/env nu -n

def main [name: string, animation_type: string, animation_speed: string] {
  let unread = (osascript -e 'tell application "Mail"
                                return the unread count of inbox
                              end tell')
  sketchybar ...[
    --animate
    $animation_type
    $animation_speed
    --set
    $name
    label=($unread)
  ]
}

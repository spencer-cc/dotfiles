#!/usr/bin/env nu -n

def docker-info [] {
  docker info --format json
  | complete
  | do {|data|
    ($data | get stdout | from json --objects)
    | insert running (
        ($data | get exit_code) == 0
      )
  } $in
  | first
}

def main [
  name: string
  animation_type: string
  animation_speed: string
  high_update_freq: string
  low_update_freq: string
] {
  let status = docker-info
  if $status.running {
    sketchybar ...[
      --animate
      $animation_type
      $animation_speed
      --set
      $name
      drawing=on
      label=($status.ContainersRunning)
      update_freq=($high_update_freq)
    ]
  } else {
    sketchybar ...[
      --set
      $name
      drawing=off
      update_freq=($low_update_freq)
    ]
  }
}

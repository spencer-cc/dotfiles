#!/usr/bin/env nu -n

def main [name: string, animation_type: string, animation_speed: string] {
  let info = $env | get -o INFO
  if ($info) != null {
    use ../core/icons.nu *
    let app = {
      name: $info
      icon: (icons "app" $info)
    }
    sketchybar ...[
      --animate
      ($animation_type)
      ($animation_speed)
      --set
      ($name)
      icon=($app.icon)
      label=($app.name)
    ]
  }
}

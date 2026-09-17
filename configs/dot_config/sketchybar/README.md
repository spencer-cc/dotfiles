# Sketchybar Configuration

A modular, Nushell-based sketchybar configuration with automatic bracket wrapping, theme integration, and a clean item/plugin architecture.

## Requirements

- [sketchybar](https://github.com/FelixKratz/SketchyBar)
- [Nushell](https://www.nushell.sh/)
- [aerospace](https://github.com/nikitabobko/AeroSpace) (window manager) for workspace widgets
- [getfocus](https://github.com/spencer-cc/getfocus_stdout) (focus mode detection) — requires **Full Disk Access** to read `~/Library/DoNotDisturb/DB/Assertions.json`. Grant via System Settings > Privacy & Security > Full Disk Access > sketchybar. Without it, the focus notifier shows a warning triangle instead of hiding.
- `softwareupdate` (built into macOS) for the update notifier — no extra dependency, but each check shells out to `softwareupdate -l`, which takes several seconds
- Fonts:
  - SpaceMono Nerd Font Mono
  - JetBrainsMono Nerd Font Mono
- Optional:
  - Docker Desktop
  - Ghostty terminal
  - tty-clock

## Quick Start

Run `just` to see all available commands for interacting with sketchybar (reload, toggle, restart, etc.).

## Debugging

Adding `print $"Item: foo=($bar)"` debugging statements will log them when running in test mode.

Use `just test-auto` to run with a time-out and receive errors/logs.

## Directory Structure

```
.config/sketchybar/
├── sketchybarrc       # Entry point - loads config, defaults, and widgets
├── config.nu          # Central configuration (theme, fonts, widget definitions)
├── core/
│   ├── defaults.nu    # Bar defaults & custom event registration
│   ├── icons.nu       # App and widget icon mappings
│   └── loader.nu      # Widget loader with auto-bracket/spacer wrapping
├── items/             # Widget registration scripts (define sketchybar items)
├── plugins/           # Widget update scripts (called by items on interval/event)
├── events/            # Custom event handlers (currently empty)
└── test/              # Test directory (currently empty)
```

## Architecture

### Entry Point Flow

```
sketchybarrc
    ├── use config.nu *         # Loads theme, fonts, widget definitions
    ├── use core/loader.nu *    # Loads load_widgets function
    ├── source core/defaults.nu # Applies bar defaults, registers events
    └── load_widgets            # Iterates widgets, calls item scripts
        └── sketchybar --update # Forces all scripts to run initially
```

The final `--update` command initializes all items by forcing their scripts to execute once on bar load.

### Items vs Plugins

The configuration follows a clear separation of concerns:

**Items** (`items/*.nu`)

- Register widgets with sketchybar using `--add item`
- Define the script path pointing to the corresponding plugin
- Set initial styling (colors, fonts, padding)
- Subscribe to events (system_woke, front_app_switched, etc.)
- Receive configuration via `$env` from `config.nu`

**Plugins** (`plugins/*.nu`)

- Execute update logic when called by sketchybar
- Receive arguments via CLI parameters from the item's script path
- Use `sketchybar --set` to update icon/label values
- Handle data fetching and formatting
- Standard arguments: `name`, `animation_type`, `animation_speed`, plus widget-specific params

**Script Path Construction Pattern**

Items construct plugin paths using a consistent pattern:

```nu
let script = [
  ($env.CONFIG_DIR)/plugins/widget_name.nu
  $env.name              # Widget identifier
  $env.animation_type    # Injected by loader
  $env.animation_speed   # Injected by loader
  $env.custom_param      # Widget-specific parameters
] | str join " "
```

This pattern ensures all plugins receive the same base arguments for consistency.

### Configuration Flow

```
config.nu (skenv.widgets)
       ↓
   $env variables
       ↓
items/<widget>.nu
       ↓
   script path construction
       ↓
plugins/<widget>.nu (CLI args)
```

**Environment Variable Flattening**

The loader flattens configuration records into environment variables:

```nu
with-env ($widget | merge {
  animation_speed: $skenv.animation.speed
  animation_type: $skenv.animation.type
}) {
  ./items/($widget.name).nu
}
```

Important constraints:

- Configuration records must be **flat** (no nested structures)
- All env vars are **strings** - booleans, times, etc require conversion: `($env.enable | into bool)`
- Complex values (colors, fonts) are passed as string references to config constants

### Dynamic Item Creation

Items can create multiple widgets dynamically. The aerospace item demonstrates this pattern:

```nu
def workspaces [] {
  ^aerospace list-workspaces --all | lines
}

workspaces | each {|workspace|
  let name = $"aerospace_($workspace)"
  sketchybar ...[
    --add item $name $env.side
    --set $name label=($workspace)
    # ... additional configuration
  ]
}
```

All items share the `aerospace_` prefix, allowing the loader to wrap them in a single bracket via regex matching.

## Design Patterns Overview

This configuration follows several key patterns documented throughout:

| Pattern           | Description                                               | See Section                                   |
| ----------------- | --------------------------------------------------------- | --------------------------------------------- |
| **Configuration** | Centralized, flat config passed via environment variables | [Widget Configuration](#widget-configuration) |
| **Loader**        | Automatic bracket wrapping and spacer insertion           | [Automatic Styling](#automatic-styling)       |
| **Events**        | Event-driven updates with special env vars                | [Events](#events)                             |
| **Performance**   | `updates=on` default so hidden items re-appear            | [Bar Defaults](#bar-defaults)                 |
| **Script Paths**  | Standardized argument passing to plugins                  | [Items vs Plugins](#items-vs-plugins)         |

## Widget Configuration

Widgets are defined in `config.nu` under `skenv.widgets`. Each widget shares common fields:

```nu
widget_name: {
  enable: true/false      # Whether to load the widget
  name: "widget_name"     # Widget identifier (must match items/<name>.nu)
  color: "0xAARRGGBB"     # Widget color (hex with alpha)
  side: left/center/right # Position on bar
  update_freq: 10         # Update interval in seconds (optional, use high/low for conditional items)
  high_update_freq: 5     # Active polling interval in seconds (optional, replaces update_freq)
  low_update_freq: 60     # Idle polling interval in seconds (optional, replaces update_freq)
  icon_font: "Font:Style:Size" # Custom icon font (optional)
}
```

### Flat Configuration Requirement

Configuration records must be flat (no nesting) because they're passed as environment variables:

```nu
# ✅ Correct - flat structure
notifiers: {
  enable: true
  name: notifiers
  restart_enable: true        # Prefixed for clarity
  restart_color: "0xFFf38ba8"
  focus_enable: true          # Prefixed for clarity
  focus_update_freq: 60
}

# ❌ Wrong - nested structure
notifiers: {
  enable: true
  name: notifiers
  restart: {                  # Won't work - nesting
    enable: true
    color: "0xFFf38ba8"
  }
}
```

### Boolean Handling

Environment variables are always strings. Booleans must be converted in item scripts:

```nu
# In config.nu
my_widget: {
  enable: true              # Boolean value
  feature_enable: true      # Boolean value
}

# In items/my_widget.nu
let enable = $env.enable | into bool        # Convert string to bool
let feature = $env.feature_enable | into bool

if $enable {
  # Create widget...
}

if $feature {
  # Add feature...
}
```

### Widget-Specific Fields

| Widget              | Special Fields                                                         |
| ------------------- | ---------------------------------------------------------------------- |
| `clock`             | `format` - strftime format string                                      |
| `aerospace`         | `color_focused`, `color_full`, `color_empty`, `label_pad`, `outer_pad` |
| `restart_notifier`  | `threshold` - uptime threshold (e.g. "7day")                           |
| `notifiers_updates` | `updates_update_freq` - seconds between `softwareupdate -l` checks     |
| `volume`            | `right_pad` - right padding value                                      |
| `docker`            | `high_update_freq`, `low_update_freq` - dynamic update speeds          |
| `weather`           | `location`, `temp_unit`, `stale_threshold`                             |

### Side Ordering

Widgets are ordered "out to in" on each side, as defined in `config.nu`:

- **Left side** (outer to inner): `apple`, `aero_mode`, `aerospace`, `focused_app`, `docker`, `restart_notifier`
- **Right side** (outer to inner): `clock`, `volume`, `battery`, `mail`, `ai-usage`, `weather`

## Adding a New Widget

### Step 1: Add Widget Configuration

In `config.nu`, add your widget to `skenv.widgets`:

```nu
my_widget: {
  enable: true
  name: my_widget
  color: $"($theme.colors.blue)"
  update_freq: 30
  side: right
}
```

### Step 2: Create Item Script

Create `items/my_widget.nu`:

```nu
#!/usr/bin/env nu -n

def main [] {
  use ../core/icons.nu *
  let icon = icons widget my_icon_name
  let script = [
    ($env.CONFIG_DIR)/plugins/my_widget.nu
    $env.name
    $env.animation_type
    $env.animation_speed
  ] | str join " "

  sketchybar ...[
    --add item $env.name $env.side
    --animate $env.animation_type $env.animation_speed
    --set $env.name
    icon=($icon)
    icon.color=($env.color)
    label.color=($env.color)
    script=($script)
    update_freq=($env.update_freq)
    --subscribe $env.name system_woke
  ]
}
```

### Step 3: Create Plugin Script

Create `plugins/my_widget.nu`:

```nu
#!/usr/bin/env nu -n

def main [
  name: string           # Widget name
  animation_type: string # Animation type
  animation_speed: string # Animation speed
] {
  let value = "your computed value"

  sketchybar ...[
    --animate $animation_type $animation_speed
    --set $name
    label=($value)
  ]
}
```

### Step 4: Add Icon (Optional)

Add your widget icon to `core/icons.nu` in the `widget_icon` function:

```nu
"my_icon_name" => ""
```

## Theming

### Color Format

Colors use hex format with alpha channel: `0xAARRGGBB`

Transparency codes:

```
100%: 0xFF
 75%: 0xBF
 50%: 0x80
 25%: 0x40
  0%: 0x00
```

### Theme Colors

Defined in `config.nu` under `theme.colors`:

```nu
const theme = {
  name: "catppuccin-mocha"
  colors: {
    transparent: "0x00ffffff"
    light_gray:  "0xFFa6adc8"
    white:       "0xFFcdd6f4"
    red:         "0xFFf38ba8"
    yellow:      "0xFFf9e2af"
    blue:        "0xFF89b4fa"
    green:       "0xFFa6e3a1"
    magenta:     "0xFFf5c2e7"
    cyan:        "0xFF89dceb"
    orange:      "0xFFfab387"
    tangerine:   "0xFFeba0ac"
    purple:      "0xFF8b6baf"
    black:       "0xFF171723"
    black_75:    "0xBF171723"
  }
}
```

### Per-Widget Colors

Each widget in `skenv.widgets` has a `color` field that references the theme:

```nu
my_widget: {
  color: $"($theme.colors.blue)"
}
```

## Events

### Custom Events

Defined in `config.nu`:

```nu
custom_events: [
  aerospace_workspace_change
  opencode-completion
]
```

These are registered in `core/defaults.nu` and can be subscribed to in item scripts.

### Built-in Events

Common events used throughout:

| Event                 | Description                       |
| --------------------- | --------------------------------- |
| `system_woke`         | System wakes from sleep           |
| `front_app_switched`  | Focused application changes       |
| `volume_change`       | System volume changes             |
| `power_source_change` | Power source changes (battery/AC) |

### Subscribing to Events

In item scripts:

```nu
--subscribe $env.name system_woke front_app_switched
```

### Special Environment Variables

When scripts execute, sketchybar provides special environment variables:

| Variable          | Description                              | Example                         |
| ----------------- | ---------------------------------------- | ------------------------------- |
| `$env.NAME`       | Name of the item that invoked the script | `"clock"`                       |
| `$env.SENDER`     | Reason for script execution (event name) | `"system_woke"`, `"routine"`    |
| `$env.INFO`       | Event-specific data                      | Front app name, volume %, etc.  |
| `$env.CONFIG_DIR` | Absolute path to config directory        | `/Users/scc/.config/sketchybar` |

**Example: Using `$env.INFO` for dynamic updates**

The `focused_app` plugin receives the front application name via `$env.INFO`:

```nu
# plugins/focused_app.nu
def main [name: string, animation_type: string, animation_speed: string] {
  let info = $env | get -o INFO
  if ($info) != null {
    use ../core/icons.nu *
    let app = {
      name: $info
      icon: (icons "app" $info)
    }
    sketchybar ...[
      --animate $animation_type $animation_speed
      --set $name
      icon=($app.icon)
      label=($app.name)
    ]
  }
}
```

When `front_app_switched` event fires, `$env.INFO` contains the application name, allowing the plugin to update icon and label accordingly.

## Icon System

The `core/icons.nu` module provides two icon functions:

### Widget Icons

```nu
icons widget <icon_name>
```

Returns Nerd Font icons for widgets (battery, volume, clock, etc.).

### App Icons

```nu
icons app <app_name>
```

Returns [sketchybar-app-font](https://github.com/kvndrsslr/sketchybar-app-font) icons for applications. Includes:

- Direct matches for 350+ applications
- Alternative name matches (localized names, aliases)
- Regex patterns for versioned apps
- Default fallback icon

### Usage in Items

```nu
use ../core/icons.nu *
let icon = icons widget clock
let app_icon = icons app "Google Chrome"
```

## Automatic Styling

The loader (`core/loader.nu`) automatically:

1. **Wraps widgets in brackets** - Adds rounded background containers
2. **Adds spacers** - Inserts spacing between widgets
3. **Applies animations** - Uses animation settings from config

### Bracket Grouping Pattern

Items with a shared name prefix are automatically wrapped in a single bracket using regex matching:

```nu
# In core/loader.nu
def add_bracket [name: string] {
  sketchybar ...[
    --add bracket $bname $"/($name).*/"
    # Regex matches: name.*, name_suffix, etc.
  ]
}
```

**Example: Multiple items in one bracket**

The `aerospace.nu` item creates:

- `aerospace_left` (padding item)
- `aerospace_1` through `aerospace_6` (workspace items)
- `aerospace_right` (padding item)

The loader wraps all items matching `/aerospace.*/` in a single bracket.

**Example: Notifiers grouping**

The `notifiers.nu` item creates:

- `notifiers_restart` (restart notification)
- `notifiers_focus` (focus mode indicator)
- `notifiers_updates` (software update indicator; click reruns the check)

Both share the `notifiers_` prefix, so one bracket wraps both items.

### Bracket Defaults

```nu
bracket: {
  height: 28
  color: "0xBF171723"  # 75% transparent black
  corner_radius: 4
  border_width: 1
}
```

## Fonts

Defined in `config.nu`:

```nu
const fonts = {
  icon: {
    family: "SpaceMono Nerd Font Mono"
    style: Bold
    size: 20
  }
  label: {
    family: "JetBrainsMono Nerd Font Mono"
    style: Bold
    size: 17
  }
  ske_app: {
    family: sketchybar-app-font
    style: Regular
    size: 14
  }
}
```

## Bar Defaults

Configured in `config.nu`:

```nu
defaults: {
  bar: {
    height: 56
    y_offset: -10
    position: top
    color: transparent
  }
  label: {
    font: $fonts.label
    padding: { left: 0, right: 8 }
    color: transparent
  }
  icon: {
    font: $fonts.icon
    padding: { left: 8, right: 6 }
    color: transparent
  }
}
```

### Performance Optimization

The global default `updates=on` (set in `core/defaults.nu`) ensures hidden items update so they can re-appear when their state changes:

```nu
sketchybar ...[
  --default
  updates=on  # Run scripts even when item is hidden, so it can re-appear
  # ... other defaults
]
```

**Why `on` instead of `when_shown`:**

- Hidden items need to run their scripts to detect state changes and re-appear
- `when_shown` would prevent hidden items from ever becoming visible again
- Items that truly don't need background updates can opt into `when_shown` individually

### Dynamic Update Frequency

Conditional items that are usually dormant (e.g., docker, which only matters when containers are running) can use **two update frequencies** instead of a single `update_freq`:

- **`low_update_freq`** - Used while the item is idle/hidden (infrequent polling to check if state changed)
- **`high_update_freq`** - Used while the item is active/visible (frequent polling for responsive updates)

The item script initializes `update_freq` to `low_update_freq` and passes both values to the plugin via CLI arguments. The plugin then switches the item's `update_freq` at runtime:

```nu
# In items/docker.nu - initialize at low frequency, pass both to plugin
update_freq=($env.low_update_freq)

# In plugins/docker.nu - switch based on state
if $status.running {
  sketchybar --set $name drawing=on update_freq=($high_update_freq)
} else {
  sketchybar --set $name drawing=off update_freq=($low_update_freq)
}
```

This avoids wasting CPU on frequent polls for items that spend most of their time idle while still providing responsive updates when active.

## Conventions

### Shebang

All Nushell scripts use:

```nu
#!/usr/bin/env nu -n
```

The `-n` flag ensures a clean environment.

### Script Path Construction

Items construct plugin paths using `$env.CONFIG_DIR`:

```nu
let script = [
  ($env.CONFIG_DIR)/plugins/widget_name.nu
  $env.name
  $env.animation_type
  $env.animation_speed
] | str join " "
```

### Sketchybar Commands

Use the spread operator for multi-argument commands:

```nu
sketchybar ...[
  --add item $name $side
  --set $name
  icon.color=($color)
  label=($value)
]
```

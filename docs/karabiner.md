# Karabiner Elements

Used for rebinding keys on macOS, at the system level.

## Management

chezmoi manages only `karabiner.json` (`configs/dot_config/private_karabiner/`).
Karabiner owns everything else in `~/.config/karabiner/` (automatic_backups,
assets, GUI-written state).

- Changing settings in the Karabiner GUI rewrites `karabiner.json` — this is
  drift. Sync it back to the repo:
  `cp ~/.config/karabiner/karabiner.json ~/dotfiles/configs/dot_config/private_karabiner/karabiner.json`
- `just dot apply` reverts GUI changes that were not synced (same loop as any
  chezmoi-managed config)
- `automatic_backups/` is Karabiner's own safety net; never commit it

## Requirements

macOS setting: `System Settings -> Keyboard -> Keyboard Shortcuts -> Function Keys -> Use F1, F2, etc. keys as standard function keys` -> _True_

## Complex Modifications

### Hyper Key

Remaps caps to mod tap behavior:

- tap: escape
- hold: hyper key (cmd + opt + ctrl)

### Function Keys

For built-in keyboard.

When the above macOS setting is false, external keyboards cannot send raw function keypresses without them being converted to media controls. When the setting is true, the f keys on the default keyboard require `fn` to use media controls.

This inverts the function key behavior so that the macbook keyboard has easy media controls, AND external keyboards can send function keys.

### Disable Hiding

This disables the `Cmd+H` hiding window behavior (conflicts with window managers).

### Additional Media Key Access

This maps unused function keys (20-24) to useful macOS media keys. This has to be done as macOS checks keyboard vendor IDs and does not accept `mission control` for example from non-apple devices.

---
name: nushell-context
description: Nushell shell configuration, autoloading behavior, and documentation resources
---

## Primary Shell

The user uses `nushell` as their primary shell. You have access to bash for tool execution.

## Autoloading

- Autoloading is managed through nushell itself and is **working correctly**
- Nushell autoloads all `$XDG_CONFIG_HOME/autoload/*.nu` files during its boot process
- **DO NOT** attempt to "fix" autoloading
- **DO NOT** waste time investigating how files in the `autoload` directory are loaded
- Other files autoloaded by nushell:
  - `config.nu`
  - `login.nu` (only if session has been set as a login session)
  - `env.nu`

## Documentation Resources

| Type               | URL                                |
| ------------------ | ---------------------------------- |
| Basics             | https://www.nushell.sh/book/       |
| Commands           | https://www.nushell.sh/commands/   |
| Language Reference | https://www.nushell.sh/lang-guide/ |
| Regex Info         | https://github.com/rust-lang/regex |

## Config Location

`~/dotfiles/configs/dot_config/nushell/` (chezmoi source — deployed to `~/.config/nushell/`)

## Common Operations

| Operation        | Command             |
| ---------------- | ------------------- |
| Get command help | `help <command>`    |
| Invoke nushell   | `nu -c "<command>"` |

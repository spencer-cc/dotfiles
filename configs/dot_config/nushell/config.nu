# NOTE:
# use `config nu --doc | nu-highlight` to retrieve documentation
# https://www.nushell.sh/book/configuration.html

# ----- Theme -----
source theme.nu
source history.nu

$env.PROMPT_INDICATOR_VI_NORMAL = ""
$env.PROMPT_INDICATOR_VI_INSERT = ""

$env.config = {
  error_style: 'short' # shorter shell errors
  error_lines: 3 # print n lines of context in errors

  # ----- Misc Settings -----
  show_banner: false
  rm: {always_trash: false}
  recursion_limit: 100 # max recursion depth before killing process

  # ----- Commandline Editor Settings -----
  buffer_editor: ["nvim"] # add arguments as other elements
  edit_mode: "emacs" # emacs or vi
  cursor_shape: {emacs: "block", vi_insert: "line", vi_normal: "block"}

  # ----- History Settings -----
  # file_format set by history.nu (chezmoi-templated, sqlite vs plaintext)
  history: {max_size: 5_000_000, isolation: true}

  # ----- Completions Settings -----
  completions: {
    algorithm: "fuzzy" # "prefix", "substring" or "fuzzy", 
    sort: "smart"
    case_sensitive: false
    quick: true
    partial: true
    use_ls_colors: true
  }

  # ----- Terminal Integrations -----
  # Controls escape codes for terminal integrations
  use_kitty_protocol: true
  shell_integration: {
    osc2: true # dir/command in title
    osc8: true # clickable filepaths
    osc133: true # report prompt location and command status
    osc633: true # VSC version of 133
    reset_application_mode: true # syncs cursors, commonly over ssh
  }

  # ----- Error Settings -----
  display_errors: {exit_code: false, termination_signal: true}

  # ----- Table Settings -----
  footer_mode: 30 # display column names in footer if table larger than window
  table: {
    mode: "light" # also consider "frameless" or "psql", 
    index_mode: auto # only show index numbers when part of data
    trim: {methodology: "truncating", truncating_suffix: "…", wrapping_try_keep_words: true}
    header_on_separator: true # place column name in table border
    abbreviated_row_count: 15
    missing_value_symbol: "--"
  }

  # ----- Datetime Settings -----
  datetime_format: {table: "%H:%M %-m/%-d/%y", normal: "%H:%M %-m/%-d/%y"}

  # ----- Filesize Units -----
  filesize: {unit: 'binary', show_unit: true, precision: 1}

  # ----- Misc Display Settings -----
  float_precision: 2 # precision for all displayed floats
  ls: {use_ls_colors: true}

  # ----- Menus -----
  menus: [
    {
      name: completion_menu
      marker: ""
      only_buffer_difference: false
      style: {
        text: $theme.text
        selected_text: {bg: $theme.surface1, fg: $theme.text}
        description_text: $theme.subtext0
        match_text: $theme.red
        selected_match_text: {bg: $theme.surface1, fg: $theme.red}
      }
      type: {
        layout: ide
        min_completion_width: 0
        max_completion_width: 100
        padding: 0
        border: true
        cursor_offset: 0
        description_mode: "right"
        min_description_width: 0
        max_description_width: 50
        max_description_height: 10
        description_offset: 1
        correct_cursor_pos: true
      }
    }
    {
      name: history_menu
      marker: ""
      only_buffer_difference: false
      style: {
        text: $theme.text
        selected_text: {bg: $theme.surface1, fg: $theme.text}
        description_text: $theme.subtext0
      }
      type: {layout: list, page_size: 10}
    }
  ]

  # ----- Hooks -----
  hooks: {display_output: "table --icons"}
}

# ----- fzf Keybindings (registered only when fzf exists) -----
if not (which fzf | is-empty) {
  $env.config.keybindings = ($env.config.keybindings? | default [] | append [
    {
      name: fzf_file
      modifier: control
      keycode: char_t
      mode: [emacs, vi_insert, vi_normal]
      event: {
        send: executehostcommand
        cmd: '
          let selection = (fd --type file --hidden --exclude .git
            | fzf --height=~12 --reverse --border rounded
              --color $"bg:-1,bg+:($theme.surface1),fg+:($theme.text),hl+:($theme.yellow),hl:($theme.yellow),border:($theme.overlay0),prompt:($theme.lavender),pointer:($theme.rosewater),marker:($theme.teal),spinner:($theme.teal),info:($theme.overlay2),query:($theme.text)")
          if ($selection | is-empty) { return }
          commandline edit --insert $selection
        '
      }
    }
    {
      name: fzf_history
      modifier: control
      keycode: char_r
      mode: [emacs, vi_insert, vi_normal]
      event: {
        send: executehostcommand
        cmd: '
          let selection = (history
            | get command
            | uniq
            | reverse
            | to text
            | fzf --height=~12 --reverse --border rounded
              --color $"bg:-1,bg+:($theme.surface1),fg+:($theme.text),hl+:($theme.yellow),hl:($theme.yellow),border:($theme.overlay0),prompt:($theme.lavender),pointer:($theme.rosewater),marker:($theme.teal),spinner:($theme.teal),info:($theme.overlay2),query:($theme.text)")
          if ($selection | is-empty) { return }
          commandline edit --replace $selection
        '
      }
    }
  ])
}

# ----- Source Rest of Config -----
source aggregator.nu

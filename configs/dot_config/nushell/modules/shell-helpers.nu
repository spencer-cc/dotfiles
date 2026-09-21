# shell interaction / navigation helpers

# ---------- INTERNAL HELPERS ----------

def nvim-completer [] {
  ls ~/.config/nvim*
  | get name
  | path basename
}

# ---------- ALIASES ----------

export alias cat = bat
export alias j = just
export alias rm = rm -I
export def cd --env --wrapped [...args: directory] { __zoxide_z ...$args }
export alias rm = rm -I

# clear shorthands
export alias c = clear
export def cls [
  --long (-l) # detailed ls
] {
  clear
  print ""
  if $long { ls -l } else { ls }
}

# unfreeze first job
export alias fg = job unfreeze (job list | reverse | where type == frozen | first | (if $in == null {null} else {$in.id}))

export def --wrapped xxd [...rest: string] {
  let max_size = 32
  let chunkbytes = 1
  let reserved = (10 + 11)
  let termcols = term size | get columns
  let num_chunks = [
    32
    (($termcols - $reserved) / (($chunkbytes * 3) + 1))
  ] | math min | math floor
  let args = [
    -autoskip
    -u
    -R
    always
    -groupsize
    $chunkbytes
    -cols
    $num_chunks
  ]
  ^xxd ...$args ...$rest
}

# ----- EXTERNAL COMMANDS -----
export alias tree = tree -aC -I .git -I .venv -I .direnv -I .idea -I .vscode -I "._*"
export alias diff = diff -u

# neovim shorthand
export def e --env --wrapped [
  ...args: path
  --config (-c): string@nvim-completer # config choice
  --clean # no config
] {
  if $clean {
    nvim --clean ...$args
  } else {
    with-env { NVIM_APPNAME: ($config | default "") } {
      nvim ...$args
    }
  }
}

# Usage:
#   `rsync [--flags] <SRC> <DEST>`
#
# Flags:
#   `--archive` archive: recursive, preserves file attributes
#   `--compress` compression
#   `--crtimes` preserve file creation times if possible
#   `--stats` post transfer summary
export alias rsync = rsync --archive --compress --crtimes --stats

# Rsync selected files (piped as filename strings) to a destination
#
# Filenames must be relative to the source directory.
# Uses rsync's --files-from=- to read the file list from stdin.
#
# Usage:
#   ls -l | sort-by modified -r | first 287 | get name | rsync-pick . /dest/
#   ls /src/ | get name | path basename | rsync-pick /src/ /dest/ --dry-run
#   ls | where size > 1mb | get name | rsync-pick . /dest/ -v
#
export def rsync-pick [
  source: path          # Source directory (base for relative paths in file list)
  destination: path     # Destination path
  ...rest: string       # Additional rsync flags (e.g. --dry-run, --delete, -v)
]: list<string> -> nothing {
  $in | to text | ^rsync --archive --compress --crtimes --stats --files-from=- $source $destination ...$rest
}

# ---------- FUNCTIONS ----------

# Reload shell configuration
export def reload [
  --login (-l) # Reload as login shell
]: nothing -> nothing {
  if $login {
    clear
    exec nu -l
  } else {
    exec nu
  }
}

# Mime the type of a file
export def mime [
  file: path # File to mime the type of
  --full (-f) # Show full mimed type (**/** vs **)
]: nothing -> string {
  ^file --mime-type -b $file
  | str trim
  | if $in =~ "cannot open" {
    return "ERR"
  } else { $in }
  | if $full {
    $in
  } else {
    $in
    match $in {
      "application/octet-stream" => "binary"
      "text/plain" => "text"
      "inode/x-empty" => "empty"
      "inode/directory" => "dir"
      $other => (
        try {
          ($other | split row '/' | get 1 | str trim)
        } catch {$other}
      )
    }
  }
}

# Rename a file or directory
# Use the up arrow to edit the current filename
export def rnm [
  path: path # Filepath to rename
]: nothing -> nothing {
  if not ($path | path exists) {
    return (error make {msg: $"Path ($path) does not exist"})
  }
  let path = $path | path expand
  let dir = $path | path dirname
  let new_path = [
    ($path | path basename)
  ] | input $"(ansi attr_bold)Rename File: (ansi reset)" --reedline
  if $new_path != "" {
    mv ($path) $"($dir)/($new_path)"
  }
}

# Manage file backups (.bak)
export def bak [
  file: path      # File to modify
  --reverse (-r)  # remove .bak from file
  --force (-f)    # overwrite if new path exists
  --keep (-k)     # copy instead of move
]: nothing -> nothing {
  if not ($file | path exists) {
    return (error make $"Path ($file) does not exist")
  }

  let target = if $reverse {
    if not ($file | str contains ".bak") {
      return (error make $"File '($file)' not a backup")
    }
    $file | str replace -r "\\.bak$" ""
  } else {
    $"($file).bak"
  }

  if ($target | path exists) and (not $force) {
    return (error make $"New path '($target)' already exists, Use -f")
  }

  if $keep {
    cp -r $file $target
    print $"($file) => ($target)"
  } else {
    mv $file $target
    print $"($file) -> ($target)"
  }
}

# Symlink Wrapper
export def symlink [
  link: path  # Location to create symlink
  file: path  # Real file
  --full (-f) # link to path from root
] {
  # force relative links
  let link = $link | str replace --regex "/$" ""
  let file = $file | str replace --regex "/$" "" | if $full { $in | path expand } else { $in }
  ^ln -s $file $link
}

# Send xterm-ghostty to remote machine
export def ghostty-xterm [
  server: string # ssh config or user@server
] {
  infocmp -x xterm-ghostty | ssh $server -- tic -x -
}

let path_additions = [
  "~/.cargo/bin"
  "~/Library/TinyTeX/bin/universal-darwin"
]

$env.PATH = (
  $env.PATH
  | append ($path_additions | where { $in | path expand | path exists })
  | append (if ("/etc/paths" | path exists) { open --raw /etc/paths | lines | where { path exists } } else { [] })
  | append (glob /etc/paths.d/** --no-dir | each { open --raw $in | lines } | flatten | where { $in | path expand | path exists })
  | uniq
)

let manpath_additions = ["/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/share/man"]

$env.MANPATH = (
  $env.MANPATH? | default "" | split row ":" | where { $in != "" }
  | append ($manpath_additions | where { $in | path exists })
  | append (if ("/etc/manpaths" | path exists) { open --raw /etc/manpaths | lines | where { path exists } } else { [] })
  | append (glob /etc/manpaths.d/** --no-dir | each { open --raw $in | lines } | flatten | where { $in | path expand | path exists })
  | uniq
  | str join ":"
)

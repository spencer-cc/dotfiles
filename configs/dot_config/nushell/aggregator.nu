# ----- Shell Tools -----
use ~/.cache/nushell/starship.nu
source ~/.cache/nushell/zoxide.nu
source ~/.cache/nushell/carapace.nu
source ~/.cache/nushell/just.nu

# ----- Configs -----

source path.nu
source completers.nu

# ---- Modules ----
use shell-helpers.nu *
use grep.nu
use clipboard.nu *
use git.nu *
use gt.nu
use synthetic.nu
use APIs.nu *
use dexcom.nu
use zj.nu
use ai.nu *
use archive.nu

use (if $nu.os-info.name == 'macos' { 'macos.nu' }) *

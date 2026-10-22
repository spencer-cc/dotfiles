# nix-darwin Homebrew configuration
# Declares casks and formulae that cannot be managed by Nix
# (GUI apps, tapped formulae, tools not in nixpkgs or broken on darwin)
# cleanup = "none" means manual brew installs are not removed
{...}: {
  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "none"; # don't remove manually installed packages
      autoUpdate = true;
      upgrade = false; # let user control upgrades
    };

    # ---- Taps ----
    taps = [
      "domcyrus/rustnet"
      "felixkratz/formulae"
      "homebrew/bundle"
      "nikitabobko/tap"
      "philocalyst/tap"
      "protonpass/tap"
    ];

    # ---- Casks (GUI apps) ----
    casks = [
      "nikitabobko/tap/aerospace"
      "alcove"
      "apparency"
      "betterdisplay"
      "caffeine"
      "discord"
      "docker-desktop"
      "ghostty"
      "helium-browser"
      "karabiner-elements"
      "mactex-no-gui"
      "obsidian"
      "proton-mail"
      "proton-pass"
      "protonvpn"
      "raspberry-pi-imager"
      "raycast"
      "shottr"
      "stremio"
      "vlc"
      "wireshark-app"
      "yubico-authenticator"
      "zen"
    ];

    # ---- Formulae (CLI tools NOT in nixpkgs or broken on darwin) ----
    brews = [
      # Service-related (felixkratz tap — not in nixpkgs)
      "felixkratz/formulae/sketchybar"
      "felixkratz/formulae/borders"

      # Network tools (not in nixpkgs or macOS-specific issues)
      "telnet"
      "whois"
      "wireshark"

      # Security/forensics tools (not in nixpkgs or broken on darwin)
      "hashcat"
      "ghidra"
      "ophcrack"
      "binwalk"

      # Libraries/build tools
      "libxcrypt"
      "binutils"
      "isync"

      # Other (fails to build on darwin)
      "poppler"

      # Tapped formulae (not in nixpkgs)
      "domcyrus/rustnet/rustnet"
      "philocalyst/tap/caligula"
      "protonpass/tap/pass-cli"
    ];

    # Note: cargo, npm, and go installs are NOT managed by nix-darwin.
    # They remain in their respective package managers:
    # cargo: cargo-update, ghgrab, metapac, nu-lint, nufmt, rusty-hook
    # npm: ocx, vercel
    # go: golang.org/dl/go1.27rc1
  };
}

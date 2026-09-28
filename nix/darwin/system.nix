# nix-darwin system configuration
# macOS system settings, nix settings, user configuration
{
  pkgs,
  username,
  homeDirectory,
  ...
}: {
  # Determinate manages Nix, not nix-darwin
  nix.enable = false;

  # nix-darwin version (set once, don't change)
  system.stateVersion = 7;

  # Primary user for user-level system options (homebrew, launchd, defaults)
  system.primaryUser = username;

  # Enable Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # User shell
  users.users.${username}.shell = "${homeDirectory}/.local/bin/nushell";

  # ---- macOS System Defaults ----
  system.defaults = {
    # Global domain settings
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      ApplePressAndHoldEnabled = false;
      AppleShowAllExtensions = true;
      AppleSpacesSwitchOnActivate = false;
      AppleEnableSwipeNavigateWithScrolls = false;
      AppleWindowTabbingMode = "manual";
      AppleKeyboardUIMode = 2;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticInlinePredictionEnabled = false;
      _HIHideMenuBar = true; # menu bar hidden
    };

    # Finder
    finder = {
      AppleShowAllFiles = true;
      ShowPathbar = true;
      ShowStatusBar = false;
      _FXShowPosixPathInTitle = true;
      FXPreferredViewStyle = "Nlsv"; # list view
      QuitMenuItem = true;
    };

    # Dock
    dock = {
      autohide = true;
      show-recents = false;
      mineffect = "scale";
      "minimize-to-application" = true;
      launchanim = false;
      magnification = false;
      orientation = "right";
      mru-spaces = false;
    };

    # Spaces — displays have separate spaces = false
    # (matches aerospace config requirement)
    spaces."spans-displays" = false;

    # Trackpad
    trackpad = {
      Clicking = false; # tap to click = off (physical click)
      TrackpadRightClick = true;
    };

    # Screenshots
    screencapture = {
      location = "/private/tmp";
    };
  };

  # System packages (nix-darwin managed, available system-wide)
  environment.systemPackages = with pkgs; [
  ];
}

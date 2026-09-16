# nix-darwin launchd services
# Manages sketchybar, aerospace, jankyborders, and obsidian as launchd agents
{
  config,
  pkgs,
  username,
  homeDirectory,
  ...
}: let
  # PATH for service processes — includes both Nix profile paths and Homebrew
  # ~/.local/state/nix/profiles/home-manager/home-path/bin: nix-darwin embedded HM
  # ~/.nix-profile/bin: standalone HM
  servicePath = "${homeDirectory}/.local/state/nix/profiles/home-manager/home-path/bin:${homeDirectory}/.nix-profile/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
in {
  launchd.user.agents = {
    # Sketchybar — custom macOS status bar
    # NOTE: Sketchybar (and the getfocus plugin for focus mode detection) requires
    # Full Disk Access to read ~/Library/DoNotDisturb/DB/Assertions.json.
    # Grant via System Settings > Privacy & Security > Full Disk Access > sketchybar.
    # Without it, getfocus exits 1 and the focus notifier shows a warning triangle.
    sketchybar = {
      serviceConfig = {
        Label = "io.github.felixkratz.sketchybar";
        ProgramArguments = ["/opt/homebrew/bin/sketchybar"];
        RunAtLoad = true;
        KeepAlive = true;
        EnvironmentVariables = {
          PATH = servicePath;
          HOME = homeDirectory;
        };
        StandardOutPath = "${homeDirectory}/Library/Logs/sketchybar.log";
        StandardErrorPath = "${homeDirectory}/Library/Logs/sketchybar.err";
      };
    };

    # AeroSpace — tiling window manager
    aerospace = {
      serviceConfig = {
        Label = "com.github.nikitabobko.aerospace";
        ProgramArguments = ["/Applications/AeroSpace.app/Contents/MacOS/aerospace"];
        RunAtLoad = true;
        KeepAlive = true;
        EnvironmentVariables = {
          PATH = servicePath;
          HOME = homeDirectory;
        };
        StandardOutPath = "${homeDirectory}/Library/Logs/aerospace.log";
        StandardErrorPath = "${homeDirectory}/Library/Logs/aerospace.err";
      };
    };

    # Jankyborders — window border system
    jankyborders = {
      serviceConfig = {
        Label = "io.github.felixkratz.borders";
        ProgramArguments = ["/opt/homebrew/bin/borders"];
        RunAtLoad = true;
        KeepAlive = true;
        EnvironmentVariables = {
          PATH = servicePath;
          HOME = homeDirectory;
        };
        StandardOutPath = "${homeDirectory}/Library/Logs/borders.log";
        StandardErrorPath = "${homeDirectory}/Library/Logs/borders.err";
      };
    };

    # Obsidian — note-taking app with background sync
    # Launches at login and on every rebuild (window floats via aerospace config).
    # No KeepAlive — if Obsidian crashes or is quit, it stays closed until next rebuild/login.
    obsidian = {
      serviceConfig = {
        Label = "md.obsidian";
        ProgramArguments = ["/Applications/Obsidian.app/Contents/MacOS/Obsidian"];
        RunAtLoad = true;
        KeepAlive = false;
        EnvironmentVariables = {
          PATH = servicePath;
          HOME = homeDirectory;
        };
      };
    };

    # dir-tidy — nightly trash of files older than 30 days in ~/Downloads
    # Script lives in the dotfiles git checkout (~/dotfiles/scripts/dir-tidy.nu).
    # Missed 3:00 AM runs fire on wake (launchd StartCalendarInterval catch-up).
    dir-tidy = {
      serviceConfig = {
        Label = "local.dir-tidy";
        ProgramArguments = [
          "${pkgs.nushell}/bin/nu"
          "--no-config-file"
          "${homeDirectory}/dotfiles/scripts/dir-tidy.nu"
        ];
        StartCalendarInterval = [{Hour = 3; Minute = 0;}];
        EnvironmentVariables = {
          PATH = servicePath;
          HOME = homeDirectory;
        };
        StandardOutPath = "${homeDirectory}/Library/Logs/dir-tidy.log";
        StandardErrorPath = "${homeDirectory}/Library/Logs/dir-tidy.err";
      };
    };
  };
}

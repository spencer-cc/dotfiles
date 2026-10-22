{
  pkgs,
  lib,
  ...
}: {
  imports = [./default.nix];

  home.packages = with pkgs;
    [
      john
      noseyparker
      aircrack-ng
      pv
      p7zip
      trufflehog
    ]
    # needs brew on macos, library issue
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      rustnet
    ];
}

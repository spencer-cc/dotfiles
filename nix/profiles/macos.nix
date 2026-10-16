{pkgs, ...}: {
  imports = [./default.nix];

  home.packages = with pkgs; [
    pngpaste
    yubikey-manager
    yubico-piv-tool
    libfido2
  ];
}

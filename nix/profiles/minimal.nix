{
  config,
  pkgs,
  username,
  homeDirectory,
  ...
}: {
  home = {
    inherit username homeDirectory;
    stateVersion = "25.05";
  };
  programs.home-manager.enable = true;
  xdg.enable = true;
  xdg.configHome = "${config.home.homeDirectory}/.config";

  home.packages = with pkgs; [
    vim
    git
    bash
    coreutils
    curl
    wget
    tree
    less
    rsync
    openssh
    chezmoi
    nushell
  ];
}

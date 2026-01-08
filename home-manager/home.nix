{
  inputs, lib, config, pkgs, ...
}: {
  imports = [];

  nixpkgs = {
    overlays = [];
    config = {
      allowUnfree = true;
    };
  };

  home = {
    username = "pigs";
    homeDirectory = "/home/pigs";
  };

  programs.home-manager.enable = true;
  programs.git.enable = true;

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    arandr
    arduino-ide
    bambu-studio
    google-chrome
    emacs
    firefox
    flameshot
    freecad
    gimp
    lxterminal
    nix-your-shell
    pavucontrol
    zoom-us
  ];

}

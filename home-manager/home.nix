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

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  # home.packages = with pkgs; [ steam ];

  programs.home-manager.enable = true;
  programs.git.enable = true;

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "24.11";

  # xsession.windowManager.xmonad = {
  #   enable = true;
  #   enableContribAndExtras = true;
  # };

  home.packages = with pkgs; [
    arandr
    arduino-ide
    bambu-studio
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

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
    firefox
    flameshot
    freecad
    gimp
    lxterminal
    nix-your-shell
    pavucontrol
    zoom-us
  ];

  programs.emacs = {
    enable = true;
    extraPackages = epkgs: [
      epkgs.docker-compose-mode
      epkgs.fish-mode
      epkgs.go-mode
      epkgs.haskell-mode
      epkgs.markdown-mode
      epkgs.nix-mode
      epkgs.nixfmt
      epkgs.rainbow-delimiters
      epkgs.rust-mode
      epkgs.smart-mode-line
      epkgs.smex
      epkgs.spaceline
      epkgs.spaceline-all-the-icons
      epkgs.typescript-mode
      epkgs.undo-tree
      epkgs.web-mode
      epkgs.yaml-mode
    ];
    extraConfig = builtins.readFile ./emacs.el;
  };

}

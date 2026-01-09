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

  programs.home-manager.enable = true;
  systemd.user.startServices = "sd-switch";
  home.stateVersion = "24.11";

  home = {
    username = "pigs";
    homeDirectory = "/home/pigs";
  };

  programs.git.enable = true;

  home.packages = with pkgs; [
    arandr
    arduino-ide
    bambu-studio
    firefox
    fishPlugins.bobthefish
    flameshot
    freecad
    gimp
    google-chrome
    lxterminal
    nix-your-shell
    pavucontrol
    powerline-fonts
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

  programs.fish = {
    enable = true;
    shellInit = ''
      set EDITOR "emacs -nw"

      if command -q nix-your-shell
        nix-your-shell fish | source
      end
    '';
    shellAbbrs = {
      f = "fg";
    };
    shellAliases = {
      emacs = "emacs -nw";
      e = "emacs -nw";
      mv = "mv -v";
      rm = "rm -v";
      ln = "ln -sv";
      cp = "cp -v";
      "..." = "cd ../..";

      g = "git";
      gl = "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      gs = "git status -sb";
      ga = "git add";
      gb = "git branch";
      gr = "git rebase";
      gm = "git merge";
      gc = "git commit";
      gd = "git diff";
      gg = "git grep";
      gp = "git push";
      go = "git checkout";
    };
  };

}

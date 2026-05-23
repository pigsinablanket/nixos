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

  programs.git = {
    enable = true;
    settings = {
      user.name = "Daniel Reimer";
      url = {
        "git@github.com:" = {
          insteadOf = "https://github.com/";
        };
      };
    };
  };

  home.packages = with pkgs; [
    arandr
    firefox
    fishPlugins.bobthefish
    flameshot
    freecad
    gimp
    google-chrome
    lxterminal
    alacritty
    nix-your-shell
    pavucontrol
    powerline-fonts
    bat
    delta
    silver-searcher
    tree
    alacritty
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
      epkgs.lsp-mode
      epkgs.lsp-ivy
      epkgs.flycheck
      epkgs.company
      epkgs.yasnippet
      epkgs.yasnippet-snippets
      epkgs.graphql-mode
      epkgs.rustic
      epkgs.cargo-mode
      epkgs.flycheck-rust
      epkgs.lsp-ui
      epkgs.projectile
      epkgs.cargo
    ];
    extraConfig = builtins.readFile ./emacs.el;
  };

  programs.fish = {
    enable = true;
    shellInit = ''
      set EDITOR "emacs -nw"

      set -U fish_user_paths /Users/dreimer/.rd/bin $fish_user_paths

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
    };
  };

}

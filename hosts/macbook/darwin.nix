{ config, pkgs, ... }:

{
  environment.systemPackages =
    [
      pkgs.home-manager
    ];

  nix = {
    package = pkgs.nix;
    enable = false;
    settings = {
      "extra-experimental-features" = [ "nix-command" "flakes" ];
    };
  };
  programs.fish.enable = true;
  users.users.dreimer.shell = pkgs.fish;

  homebrew = {
    enable = true;

    casks = [
      "rancher"
      "1password"
      "firefox"
    ];
  };

  system.defaults = {
    dock = {
      autohide = true;
    };

    finder = {
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      FXEnableExtensionChangeWarning = false;
    };
  };

  system.stateVersion = 6;

}

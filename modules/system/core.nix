{ pkgs, ... }:

{
  time.timeZone = "America/Los_Angeles";

  fonts.packages = with pkgs; [
    nerd-fonts.inconsolata
  ];

  programs.fish.enable = true;

  networking.networkmanager.enable = true;

  environment.systemPackages = with pkgs; [
    coreutils
    dig
    fd
    fish
    git
    gnumake
    htop
    jq
    lshw
    lsof
    mosh
    pciutils
    rlwrap
    silver-searcher
    unzip
    usbutils
    wget
    zip

    home-manager
    powerline-fonts
    fishPlugins.bobthefish
  ];
}

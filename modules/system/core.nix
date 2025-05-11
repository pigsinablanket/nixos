{ pkgs, ... }:

{
  time.timeZone = "America/Los_Angeles";

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "Inconsolata" ]; })
  ];

  programs.fish.enable = true;

  networking.networkmanager.enable = true;

  environment.systemPackages = with pkgs; [
    coreutils
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

    inconsolata-nerdfont
    powerline-fonts
    fishPlugins.bobthefish
  ];
}

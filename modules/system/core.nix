{ pkgs, ... }:

{
  time.timeZone = "America/Los_Angeles";

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.inconsolata
      powerline-fonts
    ];
  };

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
  ];
}

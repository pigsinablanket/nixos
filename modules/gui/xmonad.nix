{ pkgs, ... }:

{
  services.xserver = {
    enable = true;
    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
    };
  };

  environment.systemPackages = with pkgs; [
    haskellPackages.xmobar
    dmenu
  ];
}

{ pkgs, ... }:

{
  security.sudo.enable = true;

  users.extraUsers.pigs = {
    isNormalUser = true;
    home = "/home/pigs";
    extraGroups = [ "wheel" "audio" "docker" "tty" "dialout" "networkmanager" ];
    shell = pkgs.fish;
  };

}

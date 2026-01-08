{ pkgs, ... }:

{
  security.sudo.enable = true;

  users.extraUsers.pigs = {
    isNormalUser = true;
    home = "/home/pigs";
    extraGroups = [ "wheel" "audio" "docker" "tty" "dialout" ];
    shell = pkgs.fish;
  };

}

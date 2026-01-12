{ pkgs, ... }:

{
  imports = [
    ./hardware.nix

    ../../modules/gui/steam.nix
    ../../modules/gui/xmonad.nix
    ../../modules/services/docker.nix
    ../../modules/services/ssh.nix
    ../../modules/system/boot.nix
    ../../modules/system/core.nix
    ../../modules/system/nix.nix
    ../../modules/system/users.nix
    ../../modules/system/zswap.nix
  ];

  system.stateVersion = "24.11";
  networking.hostName = "pigs-desktop";

  zswap.enable = true;

  networking.firewall.checkReversePath = false;

  #services.immich = {
  #  enable = true;
  #  openFirewall = true;
  #  host = "0.0.0.0";
  #};

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };


  services.deluge = {
    enable = true;
    web.enable = true;
  };

  hardware.amdgpu.initrd.enable = true;
  hardware.amdgpu.legacySupport.enable = true;


  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /srv/nfs      192.168.1.0/24(rw,fsid=0,no_subtree_check)
    /srv/nfs/pigs 192.168.1.0/24(rw,fsid=12345,nohide,insecure,no_subtree_check)
  '';

  networking.firewall.allowedTCPPorts = [ 2049 ];

}
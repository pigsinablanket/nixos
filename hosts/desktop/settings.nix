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



  # Define VPN network namespace
  vpnNamespaces.wg = {
    enable = true;
    wireguardConfigFile = "/data/.secret/wg.conf";
    accessibleFrom = [
      "192.168.1.0/24"
    ];
    portMappings = [
      { from = 9091; to = 9091; }
    ];
    openVPNPorts = [{
      port = 60729;
      protocol = "both";
    }];
  };

  # Add systemd service to VPN network namespace
  systemd.services.transmission.vpnConfinement = {
    enable = true;
    vpnNamespace = "wg";
  };

  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    settings.download-dir = "/data/torrents";
    group = "media";
    settings = {
      "rpc-bind-address" = "192.168.15.1"; #"10.2.0.2"; # Bind RPC/WebUI to VPN network namespace address

      "rpc-whitelist" = "127.0.0.1,192.168.1.*,192.168.15.5";  # Access from other machines on specific subnet
    };
  };

  services.radarr = {
    enable = true;
    openFirewall = true;
    group = "media";
  };

  services.sonarr = {
    enable = true;
    openFirewall = true;
    group = "media";
  };

  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

  services.jellyseerr = {
    enable = true;
    openFirewall = true;
  };

  services.flaresolverr = {
    enable = true;
    openFirewall = true;
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    group = "media";
  };

  users.groups.media = {};

  systemd.tmpfiles.rules = [
    "d /data 2775 root media - -"
    "d /data/torrents 2775 root media - -"
    "d /data/torrents/movies 2775 root media - -"
    "d /data/torrents/tv 2775 root media - -"
    "d /data/media 2775 root media - -"
    "d /data/media/movies 2775 root media - -"
    "d /data/media/tv 2775 root media - -"
    "d /data/media/sports 2775 root media - -"
  ];

  #services.immich = {
  #  enable = true;
  #  openFirewall = true;
  #  host = "0.0.0.0";
  #};

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };


  # services.deluge = {
  #   enable = true;
  #   web.enable = true;
  # };

  hardware.amdgpu.initrd.enable = true;
  hardware.amdgpu.legacySupport.enable = true;


  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /srv/nfs      192.168.1.0/24(rw,fsid=0,no_subtree_check)
    /srv/nfs/pigs 192.168.1.0/24(rw,fsid=12345,nohide,insecure,no_subtree_check)
    /srv/nfs/stardew 192.168.1.0/24(rw,sync,no_root_squash,anonuid=1000,anongid=1000)
  '';

  #networking.firewall.allowedTCPPorts = [ 2049 ];

}

{ pkgs, config, lib, ... }:

let
  cfg = config.services.headscale-setup;
  headscaleUrl = "https://home.pigs.dev";
in
{
  options.services.headscale-setup = {
    enable = lib.mkEnableOption "Headscale tailnet (control plane + local client)" // {
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {

    # ─────────────────────────────────────────────
    # Headscale Control Plane
    # ─────────────────────────────────────────────
    services.headscale = {
      enable = true;
      address = "127.0.0.1";
      port = 8080;

      settings = {
        # Public URL that remote clients connect to (via Caddy reverse proxy)
        server_url = headscaleUrl;

        # ── DNS / MagicDNS ──
        dns = {
          magic_dns = true;
          base_domain = "ts.net";
          # Don't hijack general DNS — only resolve .ts.net via headscale
          override_local_dns = false;
          nameservers = {
            global = [ ];
            split = {
              "ts.net" = [ "100.64.0.1" ];
            };
          };
        };

        # ── IP Allocation ──
        prefixes = {
          v4 = "100.64.0.0/10";
          v6 = "fd7a:115c:a1e0::/48";
          allocation = "sequential";
        };

        # ── Database ──
        database = {
          type = "sqlite";
          sqlite = {
            path = "/var/lib/headscale/db.sqlite";
            write_ahead_log = true;
          };
        };

        # ── DERP ──
        derp = {
          urls = [
            "https://controlplane.tailscale.com/derpmap/default"
          ];
          auto_update_enabled = true;
          update_frequency = "24h";
        };

        # ── Logging ──
        log = {
          level = "info";
          format = "text";
        };
      };
    };

    # ─────────────────────────────────────────────
    # Tailscale Client (this machine as a tailnet node)
    # ─────────────────────────────────────────────
    # Connect via localhost to avoid hairpin NAT / TLS cert issues.
    # Remote clients use `headscaleUrl` (https://home.pigs.dev).
    services.tailscale = {
      enable = true;
      authKeyFile = config.age.secrets."tailscale-auth-key".path;
      extraUpFlags = [
        "--login-server=http://127.0.0.1:${toString config.services.headscale.port}"
      ];
    };

    # ─────────────────────────────────────────────
    # Caddy Reverse Proxy (TLS termination for headscale)
    # ─────────────────────────────────────────────
    services.caddy = {
      enable = true;
      email = "caddy@pigs.dev";

      virtualHosts."home.pigs.dev" = {
        extraConfig = ''
          reverse_proxy localhost:8080 {
            transport http {
              tls_insecure_skip_verify
            }
          }
        '';
      };
    };

    # ─────────────────────────────────────────────
    # Firewall
    # ─────────────────────────────────────────────
    networking.firewall = {
      allowedTCPPorts = [
        80   # Let's Encrypt ACME HTTP challenge
        443  # Headscale control server (HTTPS via Caddy)
      ];
      allowedUDPPorts = [
        41641 # WireGuard direct peer-to-peer
      ];
    };
  };
}

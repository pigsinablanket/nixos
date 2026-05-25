{ pkgs, config, lib, ... }:

let
  cfg = config.services.headscale-setup;
  headscaleUrl = "https://home.pigs.dev";
  headscaleBin = config.services.headscale.package;

  # Collect all users + preauth keys into a flat list for the setup script
  userKeyList = lib.flatten (
    lib.mapAttrsToList (userName: userCfg: (
      lib.mapAttrsToList (keyName: keyCfg: {
        inherit userName keyName;
        reusable = keyCfg.reusable;
        ephemeral = keyCfg.ephemeral;
        expiration = if keyCfg.expiration == null then null else keyCfg.expiration;
        tags = keyCfg.tags or [ ];
      }) userCfg.preAuthKeys
    )) cfg.users
  );

  # Generate the setup script body (pure Nix, no config thunks)
  hsConfigFile = config.services.headscale.configFile;
  keysDir = "/var/lib/headscale/keys";
  hsCmd = "headscale -c ${hsConfigFile}";

  setupScriptBody = let
    createUserCmd = u: ''
      ${hsCmd} users create ${lib.escapeShellArg u.userName} 2>/dev/null || true
    '';
    createKeyCmd = u: let
      keyDir = "${keysDir}/${lib.escapeShellArg u.userName}";
      keyPath = "${keyDir}/${lib.escapeShellArg u.keyName}";
      tagFlags = lib.concatStringsSep " " (map (t: "--tags ${lib.escapeShellArg t}") u.tags);
      expFlag = if u.expiration != null && u.expiration != "" then "--expiration ${lib.escapeShellArg u.expiration}" else "";
      reusableFlag = if u.reusable then "--reusable" else "";
      ephemeralFlag = if u.ephemeral then "--ephemeral" else "";
    in ''
      mkdir -p ${keyDir}
      if [ -f "${keyPath}" ]; then
        echo "Key ${u.userName}/${u.keyName} already exists, skipping"
      else
        KEY=$(${hsCmd} preauthkeys create --user ${lib.escapeShellArg u.userName} ${reusableFlag} ${ephemeralFlag} ${expFlag} ${tagFlags} 2>&1 | grep -oP '^[a-zA-Z0-9]+' || true)
        if [ -n "$KEY" ]; then
          echo "$KEY" > "${keyPath}"
          chmod 600 "${keyPath}"
          echo "Created key ${u.userName}/${u.keyName}"
        else
          echo "WARN: could not extract key for ${u.userName}/${u.keyName}"
        fi
      fi
    '';
  in ''
    set -euo pipefail
    echo "=== Headscale setup ==="

    ${lib.concatMapStrings createUserCmd userKeyList}
    ${lib.concatMapStrings createKeyCmd userKeyList}

    echo "=== Done ==="
  '';

  setupScript = pkgs.writeShellApplication {
    name = "headscale-setup";
    runtimeInputs = [ headscaleBin ];
    text = setupScriptBody;
  };
in
{
  options.services.headscale-setup = {
    enable = lib.mkEnableOption "Headscale tailnet (control plane + local client)" // {
      default = false;
    };

    users = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options.preAuthKeys = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              reusable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Key can be used multiple times (consumed after first use if false).";
              };
              ephemeral = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Nodes registered with this key are removed when they go offline.";
              };
              expiration = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Expiration time (e.g. \"24h\", \"7d\"). Empty for no expiry.";
              };
              tags = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Tags to assign to nodes registering with this key.";
              };
            };
          });
          default = { };
          description = "Pre-auth keys per user.";
        };
      });
      default = { };
      description = "Declarative headscale users and their pre-auth keys.";
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
        # Public URL that clients connect to (via Caddy reverse proxy)
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
        # Use Tailscale public DERP servers by default.
        # Add a self-hosted DERP later if needed.
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
    # Headscale Users / Pre-auth Keys (declarative)
    # ─────────────────────────────────────────────
    # systemd oneshot that creates users + keys after headscale starts.
    # Keys are written to /var/lib/headscale/keys/<user>/<name>
    systemd.services.headscale-setup = {
      description = "Headscale declarative user and pre-auth key setup";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${setupScript}/bin/headscale-setup";
        User = "headscale";
        Group = "headscale";
        # Ensure /var/lib/headscale is writable
        StateDirectory = "headscale";
        StateDirectoryMode = "750";
      };
      wantedBy = [ "multi-user.target" ];
      after = [ "headscale.service" ];
      requires = [ "headscale.service" ];
    };

    # ─────────────────────────────────────────────
    # Tailscale Client (this machine as a tailnet node)
    # ─────────────────────────────────────────────
    # Connect via localhost to avoid hairpin NAT / TLS cert issues.
    # Remote clients should use `headscaleUrl` (https://home.pigs.dev).
    services.tailscale = {
      enable = true;
      extraUpFlags = [
        "--login-server=http://127.0.0.1:${toString config.services.headscale.port}"
      ];
    } // (
      # If there are declared users/keys, point authKeyFile at the first one
      # and make tailscale wait for the setup service.
      if userKeyList != [ ] then let
        firstKey = builtins.head userKeyList;
        keyFile = "/var/lib/headscale/keys/${firstKey.userName}/${firstKey.keyName}";
      in {
        authKeyFile = keyFile;
      }
    else { });

    systemd.services.tailscaled.after = lib.mkAfter [ "headscale-setup.service" ];
    systemd.services.tailscaled.requires = lib.mkAfter [ "headscale-setup.service" ];

    # Autoconnect: runs after headscale-setup so the key file exists.
    # tailscale up is idempotent — skips if already authenticated.
    systemd.services.tailscaled-autoconnect.after = lib.mkAfter [ "headscale-setup.service" ];
    systemd.services.tailscaled-autoconnect.requires = lib.mkAfter [ "headscale-setup.service" ];

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

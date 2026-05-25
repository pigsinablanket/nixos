# Headscale Setup

Self-hosted Tailscale control plane on `pigs-desktop`. Remote clients connect via `https://home.pigs.dev`.

## Architecture

```
Remote client → home.pigs.dev:443 → Caddy → headscale (localhost:8080)
This machine  → localhost:8080     → headscale (direct, no TLS)
```

## First-Time Setup (one-time, manual)

After `nixos-rebuild switch`:

```bash
# 1. Create a headscale user
sudo headscale users create pigs

# 2. Generate a reusable pre-auth key
sudo headscale preauthkeys create --user pigs --reusable
# → note the output key

# 3. Register this machine
sudo tailscale up --login-server=http://127.0.0.1:8080 --authkey=<key-from-step-2>

# 4. Verify
tailscale status
```

## Register a Remote Device

```bash
# On pigs-desktop: generate a key
sudo headscale preauthkeys create --user pigs --reusable

# On the remote device (install Tailscale first):
tailscale up --login-server=https://home.pigs.dev --authkey=<key>
```

## Useful Commands

```bash
# List users
sudo headscale users list

# List nodes
sudo headscale nodes list

# List pre-auth keys
sudo headscale preauthkeys list

# Delete a node
sudo headscale nodes delete <name>

# Renew a node's keys
sudo headscale nodes auth <name>
```

## Router Port Forwarding

| Port    | Protocol | Purpose                          |
|---------|----------|----------------------------------|
| 80      | TCP      | Let's Encrypt ACME challenge     |
| 443     | TCP      | Headscale control server (HTTPS) |
| 41641   | UDP      | WireGuard direct peer-to-peer    |

## Notes

- This machine connects to headscale via `localhost:8080` (avoids hairpin NAT)
- Remote clients connect via `https://home.pigs.dev` (Caddy reverse proxy + auto TLS)
- MagicDNS is enabled — nodes are reachable as `<hostname>.ts.net`
- DERP fallback uses Tailscale's public servers

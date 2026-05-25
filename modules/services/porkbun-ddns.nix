{ pkgs, config, ... }:

let
  script = pkgs.writeShellApplication {
    name = "porkbun-ddns";
    runtimeInputs = [ pkgs.curl pkgs.jq ];
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      DOMAIN="pigs.dev"
      SUBDOMAIN="home"
      FULLNAME="$SUBDOMAIN.$DOMAIN"
      API_KEY=$(cat ${config.age.secrets."porkbun-api-key".path})
      SECRET_KEY=$(cat ${config.age.secrets."porkbun-secret-key".path})
      CACHE_FILE="/var/cache/porkbun-ddns-$FULLNAME.ip"
      API_BASE="https://api.porkbun.com/api/json/v3"

      log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

      CURRENT_IP=$(curl -s --max-time 10 https://api.ipify.org) || { log "ERROR: Failed to fetch external IP"; exit 1; }
      log "Current external IP: $CURRENT_IP"

      PREV_IP=""
      [[ -f "$CACHE_FILE" ]] && PREV_IP=$(cat "$CACHE_FILE")

      if [[ "$CURRENT_IP" == "$PREV_IP" ]]; then
          log "IP unchanged ($CURRENT_IP). No update needed."
          exit 0
      fi

      PREV_DISPLAY="$PREV_IP"
      [[ -z "$PREV_DISPLAY" ]] && PREV_DISPLAY="<none>"
      log "IP changed: $PREV_DISPLAY -> $CURRENT_IP"

      EDIT_RESPONSE=$(curl -s --max-time 15 -X POST "$API_BASE/dns/editByNameType/$DOMAIN/A/$SUBDOMAIN" \
          -H "Content-Type: application/json" \
          -d "$(jq -n \
              --arg apikey "$API_KEY" \
              --arg secretapikey "$SECRET_KEY" \
              --arg content "$CURRENT_IP" \
              '{apikey: $apikey, secretapikey: $secretapikey, content: $content, ttl: 300}')")

      EDIT_STATUS=$(echo "$EDIT_RESPONSE" | jq -r '.status // empty')

      if [[ "$EDIT_STATUS" == "SUCCESS" ]]; then
          log "Updated existing A record for $FULLNAME -> $CURRENT_IP"
          echo "$CURRENT_IP" > "$CACHE_FILE"
          exit 0
      fi

      log "Edit failed ($EDIT_STATUS). Creating new A record..."

      CREATE_RESPONSE=$(curl -s --max-time 15 -X POST "$API_BASE/dns/create/$DOMAIN" \
          -H "Content-Type: application/json" \
          -d "$(jq -n \
              --arg apikey "$API_KEY" \
              --arg secretapikey "$SECRET_KEY" \
              --arg name "$SUBDOMAIN" \
              --arg content "$CURRENT_IP" \
              '{apikey: $apikey, secretapikey: $secretapikey, name: $name, type: "A", content: $content, ttl: 300}')")

      CREATE_STATUS=$(echo "$CREATE_RESPONSE" | jq -r '.status // empty')

      if [[ "$CREATE_STATUS" == "SUCCESS" ]]; then
          log "Created new A record for $FULLNAME -> $CURRENT_IP"
          echo "$CURRENT_IP" > "$CACHE_FILE"
          exit 0
      fi

      log "ERROR: Create also failed ($CREATE_STATUS). Response: $CREATE_RESPONSE"
      exit 1
    '';
  };
in
{
  systemd.services.porkbun-ddns = {
    description = "Update Porkbun DNS A record for home.pigs.dev";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${script}/bin/porkbun-ddns";
    };
  };

  systemd.timers.porkbun-ddns = {
    description = "Run Porkbun DDNS updater every 5 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "5min";
      RandomizedDelaySec = "30s";
    };
  };
}

# searxng-agent.nix

# NixOS SearXNG module optimized for a coding agent.
# No uWSGI — SearXNG's built-in server runs on 127.0.0.1:8080,
# nginx proxies it, and openFirewall punches port 80 through.
#
# Import in configuration.nix:
#   imports = [ ./searxng-agent.nix ];
#
# Secret setup (run once):
#   install -m 600 /dev/null /run/secrets/searxng.env
#   echo "SEARXNG_SECRET=$(openssl rand -hex 32)" > /run/secrets/searxng.env
{ config, pkgs, lib, ... }:

{
  services.searx = {
    enable  = true;
    package = pkgs.searxng;

    # Secret injected at runtime — never baked into the Nix store.
    # File format:  SEARXNG_SECRET=<your-secret>
    # Generate:     openssl rand -hex 32
    # environmentFile = "/run/secrets/searxng-secret";

    # Plain HTTP server — fine for local/LAN agent use.
    # Flip to true and set domain if you want nginx + uwsgi.
    # configureUwsgi = true;
    # configureNginx = true;
    # domain = "_";

    # Open the firewall on the port defined in settings.server.port below.
    openFirewall = true;

    # Redis/valkey for rate-limiting and bot protection.
    redisCreateLocally = false;

    # limiterSettings = {
    #   real_ip = {
    #     x_for       = 1;
    #     ipv4_prefix = 32;
    #     ipv6_prefix = 56;
    #   };
    #   botdetection.ip_limit = {
    #     filter_link_local = true;
    #     # Disable CSRF link_token — breaks programmatic API clients
    #     link_token = false;
    #   };
    # };

    settings = {
      use_default_settings = true;

      general = {
        debug             = true;
        instance_name     = "agent-search";
        donation_url      = false;
        contact_url       = false;
        privacypolicy_url = false;
        enable_metrics    = true;
      };

      server = {
        port         = 8082;
        bind_address = "0.0.0.0";   # change to "0.0.0.0" for LAN access
        secret_key   = "e1b495f6b6a79aed67edbb0025626f45fd082eb911f6e24ce3135070725bb317";
        limiter      = false;
        method       = "GET";         # agents build simple query URLs
        formats      = [ "html" "json" "csv" ];
        image_proxy  = false;
        public_instance = false;
      };

      search = {
        safe_search          = 0;
        autocomplete         = "";    # agents construct full queries themselves
        autocomplete_min     = 0;
        default_lang         = "en";
        ban_time_on_fail     = 5;
        max_ban_time_on_fail = 120;
        max_page             = 3;
        formats = ["html" "json"];
      };

      ui = {
        static_use_hash           = true;
        default_locale            = "en";
        query_in_title            = false;
        infinite_scroll           = false;
        search_on_category_select = false;
        default_theme             = "simple";
      };

      outgoing = {
        request_timeout     = 4.0;   # fail fast — don't block tool calls
        max_request_timeout = 10.0;
        pool_connections    = 50;
        pool_maxsize        = 10;
        enable_http2        = true;
      };

      # Only coding-relevant engines enabled; everything visual/social is off.
      engines = lib.mapAttrsToList (name: attrs: { inherit name; } // attrs) {
        # General web fallbacks
        "bing"             = { disabled = false; weight = 1; };
        "duckduckgo"       = { disabled = false; weight = 1; };

        # Code forges and Q&A
        "github"           = { disabled = false; weight = 2; };
        "stackoverflow"    = { disabled = false; weight = 2; };
        # "superuser"        = { disabled = false; weight = 1; };
        # "askubuntu"        = { disabled = false; weight = 1; };
        # "serverfault"      = { disabled = false; weight = 1; };
        # "hn"          = { disabled = false; weight = 1; engine = "xpath"; categories = ["news"]; };
        "serverfault" = { disabled = false; weight = 1; engine = "stackexchange"; };
        "askubuntu"   = { disabled = false; weight = 1; engine = "stackexchange"; };
        "superuser"   = { disabled = false; weight = 1; engine = "stackexchange"; };

        # Reference docs
        "mdn"              = { disabled = false; weight = 2; };
        "wikipedia"        = { disabled = false; weight = 1; };
        "wikidata"         = { inactive = true; };

        # Research papers
        "arxiv"            = { disabled = false; weight = 1; };
        "semantic scholar" = { disabled = false; weight = 1; };

        # Package registries
        "pypi"             = { disabled = false; weight = 2; };
        "npm"              = { disabled = false; weight = 2; };
        "crates.io"        = { disabled = false; weight = 2; };
        "docker hub"       = { disabled = false; weight = 1; };

        # Tech news
        "hackernews"               = { disabled = false; weight = 1; };

        # Off — visual / irrelevant
        "bing images"      = { disabled = true; };
        "bing videos"      = { disabled = true; };
        "brave"            = { disabled = true; };
        "google"           = { disabled = false; weight = 2; };
        "google images"    = { disabled = true; };
        "google videos"    = { disabled = true; };
        "google news"      = { disabled = true; };
        "qwant"            = { disabled = true; };
        "youtube"          = { disabled = true; };
        "dailymotion"      = { disabled = true; };
        "pinterest"        = { disabled = true; };
        "flickr"           = { disabled = true; };
        "imgur"            = { disabled = true; };
        "deviantart"       = { disabled = true; };
        "unsplash"         = { disabled = true; };
        "currency"         = { disabled = true; };
        "dictzone"         = { disabled = true; };
        "lingva"           = { disabled = true; };
        "wikiquote"        = { disabled = true; };
        "wikisource"       = { disabled = true; };
        "wikispecies"      = { disabled = true; };
        "wikiversity"      = { disabled = true; };
        "wikivoyage"       = { disabled = true; };
        "mojeek"           = { disabled = true; };
        "mwmbl"            = { disabled = true; };
        "ahmia" = { inactive = true; };
        "torch" = { inactive = true; };
      };

      enabled_plugins = [
        "Basic Calculator"
        "Hash plugin"
        "Tracker URL remover"
        "Open Access DOI rewrite"
        "Unit converter plugin"
      ];
    };
  };
}

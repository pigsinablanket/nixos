{ pkgs, ... }:
{
  services.mediawiki = {
    enable = true;
    name = "Sample MediaWiki";
    httpd.virtualHost = {
      hostName = "localhost";
      adminAddr = "admin@example.com";
    };
    # Administrator account username is admin.
    # Set initial password to "cardbotnine" for the account admin.
    passwordFile = pkgs.writeText "password" "cardbotnine";
    extraConfig = ''
    # Disable anonymous editing
    $wgGroupPermissions['*']['edit'] = false;
    $wgShowExceptionDetails = true;
  '';

    extensions = {
      # some extensions are included and can enabled by passing null
      VisualEditor = null;

      # https://www.mediawiki.org/wiki/Extension:TemplateStyles
      TemplateStyles = pkgs.fetchzip {
        url = "https://extdist.wmflabs.org/dist/extensions/TemplateStyles-REL1_40-5c3234a.tar.gz";
        hash = "sha256-IygCDgwJ+hZ1d39OXuJMrkaxPhVuxSkHy9bWU5NeM/E=";
      };

      SyntaxHighlight = pkgs.fetchzip {
        url = "https://extdist.wmflabs.org/dist/extensions/SyntaxHighlight_GeSHi-REL1_42-2e8fb3c.tar.gz";
        hash = "sha256-dRB5mmzxYcWPlmBXn7LOO8Iedbbs651eBFUT8js8USM=";
      };

      NixOSDocs = pkgs.fetchzip {
        url = "http://localhost:8000/NixOSDocs-1.0.tar.gz";
        hash = "sha256-ajSkoDOTx6d4uDfumpOj6eKouk49El/2nbVVp1ErD0I=";
      };
    };
  };
}

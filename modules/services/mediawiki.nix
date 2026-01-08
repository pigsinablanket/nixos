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

    wfLoadExtension( 'TemplateData' );
    wfLoadExtension( 'Description2' );
    $wgEnableMetaDescriptionFunctions = true;
    wfLoadExtension( 'Mermaid' );
  '';

    extensions = {
      # some extensions are included and can enabled by passing null
      VisualEditor = null;

      TemplateData = null;

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

      Description2 = pkgs.fetchzip {
        url = "https://extdist.wmflabs.org/dist/extensions/Description2-REL1_43-50e2aef.tar.gz";
        hash = "sha256-ciUEUcg4tsgpvohuLYztFaGNBowR7p1dIKnNp4ooKtA=";
      };

      Mermaid = pkgs.fetchzip {
        url = "https://github.com/SemanticMediaWiki/Mermaid/archive/refs/tags/3.1.0.zip";
        hash = "sha256-tLOdAsXsaP/URvKcl5QWQiyhMy70qn8Fi8g3+ecNOWQ=";
      };

    };
  };
}

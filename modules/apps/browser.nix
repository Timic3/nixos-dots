{ lib, pkgs, ... }:
let
  managed = "brave/policies/managed";
  recommended = "brave/policies/recommended";
  browsers = [ "brave-browser.desktop" "firefox.desktop" ];  # First one installed wins
in
{
  programs.firefox = {
    enable = true;
    policies.DontCheckDefaultBrowser = true;
  };

  environment.systemPackages = [ pkgs.brave ];

  # Per-user because ~/.config/mimeapps.list overrides xdg.mime.defaultApplications
  home-manager.sharedModules = [{
    xdg.mimeApps = {
      enable = true;
      defaultApplications = lib.genAttrs [
        "text/html"
        "application/xhtml+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ] (_: browsers);
    };
    xdg.configFile."mimeapps.list".force = true;  # Apps can replace the link, take it back on switch
  }];

  environment.etc."${managed}/debloat.json".text = builtins.toJSON {
    BraveRewardsDisabled = true;  # Rewards / BAT crypto ads
    BraveWalletDisabled = true;  # Crypto wallet, web3, crypto domains
    BraveVPNDisabled = true;  # VPN
    BraveAIChatEnabled = false;  # Leo AI
    BraveNewsDisabled = true;
    BraveTalkDisabled = true;
    BravePlaylistEnabled = false;
    # TorDisabled = true;
  };

  environment.etc."${managed}/privacy.json".text = builtins.toJSON {
    BraveP3AEnabled = false;  # Anonymous usage analytics
    BraveStatsPingEnabled = false;  # Daily usage ping
    BraveWebDiscoveryEnabled = false;

    MetricsReportingEnabled = false;
    UrlKeyedAnonymizedDataCollectionEnabled = false;
    SpellCheckServiceEnabled = false;
  };

  environment.etc."${managed}/behavior.json".text = builtins.toJSON {
    DefaultBrowserSettingEnabled = false;  # Don't nag me about default browser
    BackgroundModeEnabled = false;
  };

  environment.etc."${managed}/passwords.json".text = builtins.toJSON {
    PasswordManagerEnabled = false;  # Bitwarden will handle passwords
    AutofillCreditCardEnabled = false;
  };

  environment.etc."${managed}/extensions.json".text = builtins.toJSON {
    ExtensionInstallForcelist = map (id: "${id};https://clients2.google.com/service/update2/crx") [
      "nngceckbapebfimnlniiiahkandclblb"  # Bitwarden
      "ecanpcehffngcegjmadlcijfolapggal"  # IPvFoo
      "mnjggcdmjocbbbhaepdhchncahnbgone"  # SponsorBlock
    ];
  };

  environment.etc."${recommended}/defaults.json".text = builtins.toJSON {
    RestoreOnStartup = 1;  # Continue where we left off

    DefaultSearchProviderEnabled = true;
    DefaultSearchProviderName = "Google";
    DefaultSearchProviderSearchURL = "https://www.google.com/search?q={searchTerms}";
    DefaultSearchProviderSuggestURL = "https://www.google.com/complete/search?client=chrome&q={searchTerms}";
  };
}

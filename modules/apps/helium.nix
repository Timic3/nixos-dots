{ pkgs, ... }:
let
  managed = "chromium/policies/managed";  # Helium reads Chromium's policy dir
  recommended = "chromium/policies/recommended";
in
{
  environment.systemPackages = [ pkgs.helium ];

  # Helium only loads Widevine (DRM: Crunchyroll, Netflix, ...) through this per-profile pointer. Its own component
  # download should write it but doesn't (imputnet/helium-linux#331), so point it at nixpkgs' copy of Google's module.
  home-manager.sharedModules = [{
    xdg.configFile."net.imput.helium/WidevineCdm/latest-component-updated-widevine-cdm" = {
      text = builtins.toJSON { Path = "${pkgs.widevine-cdm}/share/google/chrome/WidevineCdm"; };
      force = true;  # Helium may rewrite it, take it back on switch
    };
  }];

  # Brave's Chromium-generic policies from browser.nix, copied. The Brave* ones don't exist here.
  environment.etc."${managed}/privacy.json".text = builtins.toJSON {
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
    # No update URL, so Helium uses its own web store route (via its services) instead of going straight to Google
    ExtensionInstallForcelist = [
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

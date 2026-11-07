{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    inter
  ];

  fonts.fontconfig.defaultFonts = {
    monospace = [ "JetBrainsMono Nerd Font" ];
    sansSerif = [ "Inter" ];
  };

  # GTK's UI font, which browsers also use for their own UI and for `system-ui` on pages. Unset it's GNOME's
  # 'Adwaita Sans', which isn't installed, so fontconfig picks Noto Sans CJK KR, and its carons land beside the letter (š → sˇ).
  home-manager.sharedModules = [{
    gtk = {
      enable = true;
      font = { name = "Inter"; size = 11; };
    };
  }];
}

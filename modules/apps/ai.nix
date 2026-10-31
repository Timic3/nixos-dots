{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    claude-code
    codex
  ];

  # Login links back into Claude Code
  home-manager.sharedModules = [{
    xdg.mimeApps.defaultApplications."x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
  }];
}

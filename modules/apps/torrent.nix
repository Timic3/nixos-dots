{ lib, pkgs, ... }:
{
  environment.systemPackages = [ pkgs.qbittorrent ];

  home-manager.sharedModules = [{
    # Magnet links from the browser and downloaded .torrent files open straight in qBittorrent
    xdg.mimeApps.defaultApplications = lib.genAttrs [
      "application/x-bittorrent"
      "x-scheme-handler/magnet"
    ] (_: "org.qbittorrent.qBittorrent.desktop");
  }];
}

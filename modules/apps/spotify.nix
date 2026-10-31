{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.spotify ];

  # networking.firewall.allowedTCPPorts = [ 57621 ];  # Synchronize local files to phones on the local network
  # networking.firewall.allowedUDPPorts = [ 5353 ];  # Find Chromecast / Spotify Connect speakers
}
